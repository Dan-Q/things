# frozen_string_literal: true

xml.instruct! :xml, version: '1.0', encoding: 'utf-8'
xml.rss version: '2.0', 'xmlns:atom' => 'http://www.w3.org/2005/Atom' do
  xml.channel do
    xml.title "Dan Q's Things"
    xml.description 'Things Dan Q has made and put onto the Internet.'
    xml.link 'https://things.danq.me/'
    xml.language 'en-GB'
    xml.lastBuildDate(ordered_things.sort_by{|thing| thing.created}.first.created.to_time.rfc2822)
    xml.tag!('atom:link', href: 'https://things.danq.me/feed.xml', rel: 'self', type: 'application/rss+xml')

    ordered_things.sort_by{|thing| thing.created}.reverse.each do |thing|
      xml.item do
        xml.guid thing.url || thing.about || thing.source
        xml.link thing.url || thing.about || thing.source
        xml.title thing.name
        xml.pubDate thing.created.rfc2822
        xml.description thing.description
      end
    end
  end
end
