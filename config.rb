# Activate and configure extensions
# https://middlemanapp.com/advanced/configuration/#configuring-extensions

activate :autoprefixer do |prefix|
  prefix.browsers = "last 2 versions"
end

# Screenshots: things with `screenshot:` instead of `image:` get a (cached)
# Puppeteer screenshot, which is copied into the build's images/ directory
require_relative 'lib/screenshots'
require_relative 'lib/podcast'

screenshot_files = {}

before_build do
  raw = YAML.safe_load(File.read(File.join(__dir__, 'data', 'things.yml')))
  screenshot_files.merge!(Screenshots.generate(raw))
end

after_build do |builder|
  images_dir = File.join(config[:build_dir], 'images')
  FileUtils.mkdir_p(images_dir)
  screenshot_files.each_value do |path|
    FileUtils.cp(path, images_dir)
    builder.thor.say_status :create, File.join('images', File.basename(path))
  end
end

# Holds the one-per-build semi-shuffled ordering, so every front-end sees the same order
module ThingsOrder
  class << self
    attr_accessor :memo
  end
end

helpers do
  # The image for a thing: its `image:`, or else its screenshot (if one exists)
  def thing_image(thing)
    return thing.image if thing.image
    return unless thing.screenshot
    file = Screenshots.filename_for('name' => thing.name, 'url' => thing.url, 'screenshot' => thing.screenshot)
    file if File.exist?(File.join(Screenshots::CACHE_DIR, file))
  end

  # All Things, semi-shuffled (dead/abandoned sink, weighted and imaged ones float up,
  # plus a random jitter), each with `image` already resolved and, for things with a
  # `podcast:` feed, `latest_episode` (title, link, enclosure) fetched from it. Computed once per build.
  def ordered_things
    ThingsOrder.memo ||= data.things.map { |thing|
      image = thing_image(thing)
      score = (%w[Dead Down].include?(thing.status) ? -3 : 0) +
              (thing.status == 'Abandoned' ? -2 : 0) +
              (thing.weight || 0) + (image ? 1 : 0) + rand
      attrs = thing.to_h.merge('image' => image, 'created' => (thing.created || '2020-09-07').to_time)
      attrs['podcast_episode'] = Podcast.latest_episode(thing.podcast) if thing.podcast
      [score, attrs]
    }.sort_by(&:first).reverse.map { |_, attrs| Hashie::Mash.new(attrs) }
  end
end

# Layouts
# https://middlemanapp.com/basics/layouts/

# Per-page layout changes
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page '/path/to/file.html', layout: 'other_layout'

# Proxy pages
# https://middlemanapp.com/advanced/dynamic-pages/

# proxy(
#   '/this-page-has-no-template.html',
#   '/template-file.html',
#   locals: {
#     which_fake_page: 'Rendering a fake page with a local variable'
#   },
# )

# Helpers
# Methods defined in the helpers block are available in templates
# https://middlemanapp.com/basics/helper-methods/

# helpers do
#   def some_helper
#     'Helping'
#   end
# end

# Build-specific configuration
# https://middlemanapp.com/advanced/configuration/#environment-specific-settings

# configure :build do
#   activate :minify_css
#   activate :minify_javascript
# end
