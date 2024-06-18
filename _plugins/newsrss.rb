require "rss"
require "yaml"

class NewsRss < Jekyll::Generator
   safe true
   priority :high
   def generate(site)
      source = YAML.load_file('_config.yml').dig('rss', 'source')
      feed = RSS::Parser.parse(URI.open(source)).items rescue []

      collection = Jekyll::Collection.new(site, 'rss')
      site.collections['rss'] = collection

      feed.each do |item|
         guid = item.guid.content.split('/')[-1]
         path = "_rss/" + guid.to_s + ".md"
         path = site.in_source_dir(path)
         doc = Jekyll::Document.new(path, { :site => site, :collection => collection })
         doc.data['title'] = item.title
         doc.data['description'] = item.description
         doc.data['link'] = item.link
         doc.data['date'] = item.pubDate
         doc.data['author'] = item.author.split('(')[1][0..-2]
         doc.data['image'] = item.enclosure.url if item.enclosure && item.enclosure.type.split('/')[0] == 'image'
         collection.docs << doc
      end
   end
end
