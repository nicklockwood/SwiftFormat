# frozen_string_literal: true

require 'open3'

# Generates the site's Markdown pages from the repo's existing docs.
#
#  - `index.md` is generated from `README.md`
#  - `rules.md` is generated from `Rules.md`
#
# Both source files are kept in sync by the project's normal workflow, so the
# site always reflects the latest docs without any manual duplication.
#
# Each generated page starts with a kramdown `{:toc}` marker, which is rendered
# as a nested list of the page's headings. The site layout relocates that list
# into a sidebar (see `_layouts/default.html`).
class SiteContent
  # kramdown replaces this list with an auto-generated table of contents.
  TOC_MARKER = "* toc\n{:toc}"

  attr_reader :readme_path, :rules_path, :index_path, :rules_page_path, :syntax_css_path

  def initialize
    site_dir = File.expand_path('src', __dir__)
    repo_dir = File.expand_path('..', __dir__)
    @readme_path = File.join(repo_dir, 'README.md')
    @rules_path = File.join(repo_dir, 'Rules.md')
    @index_path = File.join(site_dir, 'index.md')
    @rules_page_path = File.join(site_dir, 'rules.md')
    @syntax_css_path = File.join(site_dir, 'assets/css/syntax.css')
  end

  # Write index.md from the repo README.md.
  def write_index
    front_matter = <<~FRONT
      ---
      layout: default
      title: SwiftFormat
      description: A command-line tool and Xcode extension for reformatting Swift code.
      ---

    FRONT
    # Only the top-level (H2) sections are worth a sidebar entry on this page;
    # nested subsections (e.g. per-package-manager install steps) would make
    # the TOC too noisy.
    File.write(index_path, front_matter + with_toc(readme_body, toc_levels: '2..2'))
  end

  # Write rules.md from the repo Rules.md.
  def write_rules
    front_matter = <<~FRONT
      ---
      layout: default
      permalink: /rules
      title: SwiftFormat Rules
      description: The full list of formatting rules supported by SwiftFormat.
      ---

    FRONT
    File.write(rules_page_path, front_matter + with_toc(rules_body))
  end

  # Write syntax.css used for code block highlighting.
  def generate_syntax_css
    light_css = syntax_css_for('github.light')
    dark_css = syntax_css_for('github.dark')

    css = [
      light_css.chomp,
      '',
      '@media (prefers-color-scheme: dark) {',
      indent_css(dark_css).rstrip,
      '}',
    ].join("\n")

    File.write(syntax_css_path, "#{css}\n")
  end

  private

  def syntax_css_for(theme)
    stdout, stderr, status = Open3.capture3('bundle', 'exec', 'rougify', 'style', theme)
    raise "rougify failed for #{theme}:\n#{stderr}" unless status.success?

    stdout
  end

  def indent_css(css)
    css.lines.map { |line| line.strip.empty? ? line : "  #{line}" }.join
  end

  # Prepends the table-of-contents marker to a page's body. `toc_levels`
  # overrides the site-wide `kramdown.toc_levels` config (see `_config.yml`)
  # just for this page, via kramdown's `{::options ... /}` extension.
  def with_toc(body, toc_levels: nil)
    marker = toc_levels ? "{::options toc_levels=\"#{toc_levels}\" /}\n#{TOC_MARKER}" : TOC_MARKER
    collapse_blank_lines("#{marker}\n\n#{pad_code_fences(body)}")
  end

  # kramdown only recognizes a fenced code block when it's preceded by a blank
  # line (unlike GitHub). Some README code blocks follow a list item or
  # sentence directly, so insert a blank line before each top-level fence to
  # stop their first line (e.g. `# Lint.yml`) being parsed as a heading.
  def pad_code_fences(markdown)
    inside_fence = false
    output = []
    markdown.split("\n", -1).each do |line|
      if line.start_with?('```')
        output << '' if !inside_fence && output.last && !output.last.empty?
        inside_fence = !inside_fence
      end
      output << line
    end
    output.join("\n")
  end

  # README.md, with its inline "Table of Contents" section removed (it's
  # replaced by the sidebar TOC) and badges / repo-relative images stripped.
  # A title and subtitle are prepended as the page header.
  def readme_body
    lines = File.readlines(readme_path, chomp: true)
    lines = strip_readme_toc(lines)
    lines = strip_badges_and_local_images(lines)
    lines = expand_details(lines)
    [index_header, lines.map(&:rstrip).join("\n")].join("\n")
  end

  # Title and subtitle shown at the top of the index page. `{:.no_toc}` keeps
  # the title out of the sidebar table of contents.
  def index_header
    <<~HEADER
      # SwiftFormat
      {:.no_toc}

      A command-line tool and Xcode Extension for formatting Swift code
      {: .heading-note}
    HEADER
  end

  # Removes `<details>` / `<summary>` wrappers so collapsible "Examples"
  # blocks render fully expanded on the site.
  def expand_details(lines)
    lines.reject do |line|
      stripped = line.strip
      stripped.start_with?('<details') ||
        stripped == '</details>' ||
        stripped.match?(%r{\A<summary>.*</summary>\z})
    end
  end

  # Removes the "Table of Contents" setext section from the README, from its
  # heading up to (but not including) the next section heading.
  def strip_readme_toc(lines)
    start = (0...lines.length).find do |i|
      lines[i].strip == 'Table of Contents' && setext_underline?(lines[i + 1])
    end
    return lines unless start

    finish = ((start + 2)...lines.length).find do |i|
      !lines[i].strip.empty? && setext_underline?(lines[i + 1])
    end
    finish ||= lines.length

    lines[0...start] + lines[finish..]
  end

  # True if `line` is a setext heading underline (a run of `-` or `=`).
  def setext_underline?(line)
    line.to_s.match?(/\A(-+|=+)\z/)
  end

  # A line consisting solely of one or more linked-image badges,
  # e.g. `[![Build](img)](href) [![License](img)](href)`.
  BADGE_LINE = /\A(?:\[!\[[^\]]*\]\([^)]*\)\]\([^)]*\)\s*)+\z/.freeze

  # Removes badge rows and repo-relative image references that only resolve
  # inside the repo (both add noise or break on the website).
  def strip_badges_and_local_images(lines)
    lines.reject do |line|
      stripped = line.strip
      local_image = stripped.start_with?('![](') && !stripped.include?('http')
      stripped.match?(BADGE_LINE) || local_image
    end
  end

  # Rules.md rebuilt so each rule's `## section` is physically grouped under
  # its category (`# Default Rules`, `# Opt-in Rules`, `# Deprecated Rules`).
  #
  # In the source file the categories are only expressed as link lists at the
  # top, while every rule section lives in one flat alphabetical run below.
  # Regrouping them lets kramdown's `{:toc}` nest each rule under its category.
  def rules_body
    lines = expand_details(File.readlines(rules_path, chomp: true))
    body_start = lines.index { |line| line.start_with?('## ') }

    categories = parse_rule_categories(lines[0...body_start])
    sections = parse_rule_sections(lines[body_start..])

    used = []
    grouped = categories.map do |category|
      rule_sections = category[:rules].filter_map do |name|
        used << name
        sections[name]
      end
      header = [category[:title]]
      # The `{: .heading-note}` IAL tags the description paragraph so it can
      # be styled as a muted label instead of a regular line of body text.
      header += ['', category[:description], '{: .heading-note}'] if category[:description]
      (header + [''] + rule_sections).join("\n")
    end

    # Guard against silently dropping a rule that isn't listed in any category.
    leftover = sections.keys - used
    grouped << leftover.map { |name| sections[name] }.join("\n") unless leftover.empty?

    grouped.join("\n")
  end

  # Parses the category link lists at the top of Rules.md into
  # `[{ title: "# Default Rules", description: "Enabled by default.", rules: ["andOperator", ...] }, ...]`.
  def parse_rule_categories(header_lines)
    categories = []
    header_lines.each do |line|
      if line.start_with?('# ')
        categories << split_category_title(line).merge(rules: [])
      elsif (match = line.match(/^\* \[([^\]]+)\]/)) && !categories.empty?
        categories.last[:rules] << match[1]
      end
    end
    categories
  end

  # Matches a category heading with a trailing parenthetical, e.g.
  # "# Default Rules (enabled by default)".
  CATEGORY_TITLE_PATTERN = /\A(?<heading>#\s+.+?)\s*\((?<note>[^)]+)\)\s*\z/.freeze

  # Splits a category heading's trailing parenthetical (e.g. "(enabled by
  # default)") out of the heading text and into a sentence-case description
  # shown as regular text below it, so it isn't rendered as part of the
  # heading itself (which also keeps it out of the sidebar TOC entry).
  def split_category_title(line)
    match = line.match(CATEGORY_TITLE_PATTERN)
    return { title: line, description: nil } unless match

    note = match[:note]
    { title: match[:heading], description: "#{note[0].upcase}#{note[1..]}" }
  end

  # Splits the rule sections into `{ "ruleName" => "## ruleName\n...section" }`.
  def parse_rule_sections(body_lines)
    sections = {}
    name = nil
    current = []
    body_lines.each do |line|
      if (match = line.match(/^## (\S+)/))
        sections[name] = current.join("\n") if name
        name = match[1]
        current = [line]
      else
        current << line
      end
    end
    sections[name] = current.join("\n") if name
    sections
  end

  def collapse_blank_lines(content)
    "#{content}\n".gsub(/\n{3,}/, "\n\n")
  end
end
