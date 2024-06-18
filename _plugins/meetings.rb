require 'icalendar/recurrence'
require 'active_support/time'
require 'yaml'

class Meetings < Jekyll::Generator
   safe true
   priority :high
   def generate(site)
     source = YAML.load_file('_config.yml').dig('calendar', 'source')
     meetings = Icalendar::Calendar.parse(URI.open(source)).first.events rescue []

     collection = Jekyll::Collection.new(site, 'meetings')
     site.collections['meetings'] = collection

     meetings.each do |meeting|
        next unless (occurrence = meeting.schedule.ice_cube_schedule.next_occurrence)

        path = "_meetings/" + meeting.uid + ".md"
        path = site.in_source_dir(path)
        doc = Jekyll::Document.new(path, { :site => site, :collection => collection })
        doc.data['title'] = meeting.summary
        doc.data['description'] = meeting.description
        doc.data['link'] = meeting.url.value.to_s
        doc.data['date'] = occurrence.start_time.utc
        doc.data['end'] = occurrence.end_time.utc
        doc.data['background'] = meeting.color
        red = relative_luminance(meeting.color[1..2])
        green = relative_luminance(meeting.color[3..4])
        blue = relative_luminance(meeting.color[5..6])
        doc.data['foreground'] = (0.2126 * red + 0.7152 * green + 0.0722 * blue) > 0.179 ? 'black' : 'white'
        collection.docs << doc
     end
     collection.docs.sort_by! { |m| m.data['date'] }
  end

  private

  # https://www.w3.org/TR/WCAG20/#relativeluminancedef
  def relative_luminance(color)
    color = color.to_i(16) / 255.0
    return color/12.92 if color <= 0.03928

    ((color + 0.055)/1.055) ** 2.4
  end
end
