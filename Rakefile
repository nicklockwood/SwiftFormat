namespace :site do
  desc 'Generates index.md, rules.md, and syntax highlighting assets'
  task :prepare do
    require_relative 'site/site_content'
    site_content = SiteContent.new
    puts '📋 Generating index.md from README.md...'
    site_content.write_index
    puts '📋 Generating rules.md from Rules.md...'
    site_content.write_rules
    puts '🎨 Generating syntax highlighting CSS...'
    site_content.generate_syntax_css
  end

  desc 'Builds the static site into _site/'
  task build: :prepare do
    env = { 'JEKYLL_ENV' => ENV.fetch('JEKYLL_ENV', 'production') }
    sh env, 'bundle exec jekyll build --source site/src'
  end

  desc 'Serves the site locally for previewing during development'
  task serve: :prepare do
    env = { 'JEKYLL_ENV' => 'development' }
    sh env, 'bundle exec jekyll serve --source site/src'
  end
end
