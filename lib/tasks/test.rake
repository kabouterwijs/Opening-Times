require 'progressbar'
require 'builder'

namespace :test do

  task(:kml => [:environment]) do
    file_path = "#{RAILS_ROOT}/public/export/facilities.kml"
    progress = ProgressBar.new("Exporting XML", Facility.count)

    File.open(file_path,"w") do |file|
      xml = Builder::XmlMarkup.new(:indent => 2, :target => file)
      xml.instruct!
      xml.kml( :xmlns => "http://earth.google.com/kml/2.2" ) do

        xml.Folder do
          xml.name "Test 1"

          xml.Style :id => "myicon" do
            xml.IconStyle do
              xml.scale 0.1
              xml.Icon do
                xml.href "http://localhost/images/block_2x2.png"
              end
            end
          end

          Facility.find(:all).each do |facility|
            progress.inc
            facility.normal_openings.each do |o|
              xml.Placemark do
                #xml.name facility.full_name
                #xml.description facility.summary_normal_openings
                xml.styleUrl "#myicon"
                xml.Point do
                  xml.coordinates "#{facility.lng},#{facility.lat}"
                end
                xml.TimeSpan do
                  date = (5 + o.sequence).to_s.rjust(2,"0")
                  xml.tag!(:begin, "2009-01-#{date}T#{o.opens_at("%H:%M")}:00Z")
                  date = (date.to_i + 1).to_s.rjust(2,"0") if 1440 == o.closes_mins
                  xml.tag!(:end, "2009-01-#{date}T#{o.closes_at("%H:%M")}:00Z")
                end
              end
            end
          end
        end
      end
    end
    progress.finish
  end

end

