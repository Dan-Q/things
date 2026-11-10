require 'net/http'
require 'nokogiri'
require 'uri'

# Fetches a podcast RSS feed and extracts its latest episode
module Podcast
  MAX_REDIRECTS = 5

  module_function

  # Returns { 'title', 'link', 'enclosure' } for the first <item> in the feed,
  # or nil (with a warning) if the feed can't be fetched or parsed
  def latest_episode(feed_url)
    doc = Nokogiri::XML(fetch(feed_url))
    item = doc.at_xpath('//item')
    return warn_and_nil(feed_url, 'no <item> found') unless item
    {
      'title'     => item.at_xpath('title')&.text&.strip,
      'link'      => item.at_xpath('link')&.text&.strip,
      'enclosure' => item.at_xpath('enclosure/@url')&.value
    }
  rescue StandardError => e
    warn_and_nil(feed_url, e.message)
  end

  def fetch(url, redirects = MAX_REDIRECTS)
    uri = URI(url)
    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https', open_timeout: 10, read_timeout: 20) do |http|
      http.get(uri.request_uri)
    end
    case res
    when Net::HTTPSuccess then res.body
    when Net::HTTPRedirection
      raise 'too many redirects' if redirects.zero?
      fetch(URI.join(url, res['location']).to_s, redirects - 1)
    else raise "HTTP #{res.code}"
    end
  end

  def warn_and_nil(url, msg)
    warn "Podcast: could not read latest episode from #{url}: #{msg}"
    nil
  end
end
