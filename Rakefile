namespace :site do
  desc 'Generates index.md, rules.md, and syntax highlighting assets'
  task :prepare do
    require_relative 'site/site_content'
    site_content = SiteContent.new
    puts '📋 Generating index.md from README.md...'
    site_content.write_index
    puts '📋 Generating rules.md from Rules.md...'
    site_content.write_rules
    puts '📋 Generating rules-prerelease.md from the develop branch\'s Rules.md...'
    site_content.write_rules_prerelease
    puts '🎨 Generating syntax highlighting CSS...'
    site_content.generate_syntax_css
    puts '🏷️  Generating build.yml (version + last updated date)...'
    site_content.write_build_info
    site_content.write_develop_info
  end

  desc 'Builds the static site into _site/'
  task build: :prepare do
    env = { 'JEKYLL_ENV' => ENV.fetch('JEKYLL_ENV', 'production') }
    command = 'bundle exec jekyll build --source site/src'
    # On a GitHub Pages project site the pages are served under a base path
    # (e.g. /SwiftFormat). The deploy workflow passes it in via PAGES_BASE_PATH
    # so `relative_url` links resolve correctly; it's empty for local builds
    # and custom domains.
    base_path = ENV['PAGES_BASE_PATH']
    command += " --baseurl #{base_path}" if base_path && !base_path.empty?
    sh env, command
  end

  desc 'Serves the site locally for previewing during development'
  task serve: :prepare do
    env = { 'JEKYLL_ENV' => 'development' }
    sh env, 'bundle exec jekyll serve --source site/src'
  end
end
