require 'fileutils'
require 'digest'
require 'json'
require 'open3'

# Generates (and caches) screenshots for "things" that specify `screenshot:`
# instead of `image:`, using Puppeteer via scripts/screenshot.js.
module Screenshots
  CACHE_MAX_AGE = 7 * 24 * 60 * 60 # seconds
  CACHE_DIR     = File.expand_path('../screenshots', __dir__)
  SCRIPT        = File.expand_path('../scripts/screenshot.js', __dir__)
  DEFAULT_WIDTH  = 1920
  DEFAULT_HEIGHT = 1080
  EXTENSION     = 'webp'

  module_function

  # Things (raw hashes from YAML) that want a screenshot instead of an image
  def wanted(things)
    things.select { |t| t['screenshot'] && !t['image'] }
  end

  def filename_for(thing)
    slug = thing['name'].to_s.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
    # The hash of what is being captured means a changed URL/size is a cache miss
    opts = options_for(thing)
    digest = Digest::SHA256.hexdigest([opts['url'], opts['width'], opts['height']].join('|'))[0, 10]
    "#{slug.empty? ? 'thing' : slug}-#{digest}.#{EXTENSION}"
  end

  def path_for(thing)
    File.join(CACHE_DIR, filename_for(thing))
  end

  def fresh?(path)
    File.exist?(path) && (Time.now - File.mtime(path)) < CACHE_MAX_AGE
  end

  # `screenshot:` may be a bare URL string or a hash with url/width/height
  def options_for(thing)
    s = thing['screenshot']
    s = { 'url' => s } unless s.is_a?(Hash)
    {
      'url'    => s['url'] || thing['url'],
      'width'  => (s['width']  || DEFAULT_WIDTH).to_i,
      'height' => (s['height'] || DEFAULT_HEIGHT).to_i
    }
  end

  # Takes any missing/stale screenshots; returns { thing name => cached file path }
  def generate(things)
    FileUtils.mkdir_p(CACHE_DIR)
    wanted_things = wanted(things)
    stale = wanted_things.reject { |t| fresh?(path_for(t)) }

    unless stale.empty?
      jobs = stale.map { |t| options_for(t).merge('name' => t['name'], 'output' => path_for(t)) }
      puts "== Screenshots: capturing #{jobs.map { |j| j['name'] }.join(', ')}"
      out, status = Open3.capture2e('node', SCRIPT, JSON.generate(jobs), chdir: File.dirname(SCRIPT))
      puts out unless out.empty?
      warn "== Screenshots: capture script exited with #{status.exitstatus}" unless status.success?
    end

    # Anything that failed but has an old cached copy still gets used
    wanted_things.each_with_object({}) do |t, h|
      path = path_for(t)
      h[t['name']] = path if File.exist?(path)
    end
  end
end
