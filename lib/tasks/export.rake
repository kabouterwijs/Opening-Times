require 'ftools'
require "progressbar"

namespace :export do

  task(:xml => [:environment]) do
    facilities = Facility.all

    if facilities.empty?
      puts "No facilties" and return
    end
    
    Dir.glob("export/*").each do |file|
      File.delete(file)
    end

    progress = ProgressBar.new("Exporting", facilities.size)
    facilities.each do |facility|
      File.open("export/#{facility.slug}.xml", "w") do |file|
        progress.inc
        file << facility.to_xml
      end
    end
    progress.finish
  end

  task(:csv => :environment) do 
    require 'fastercsv'
    FasterCSV.open("export/facilities.csv","w") do |csv|
      csv << ["name","address","Mon","Tue","Wed","Thu","Fri","Sat","Sun"]
      Facility.find(:all, :limit => 10).each do |facility|
        counter = 0
        data = []
        data << facility.full_name
        data << facility.full_address
        [1,2,3,4,5,6,0].each do |day| # Each day of the week
          opening = facility.normal_openings[counter]
          day_data = []
          while opening && opening.wday == day # if the opening is for this day
            counter += 1
            day_data << opening.summary
            opening = facility.normal_openings[counter]
          end
          data << day_data.join("\r\n")
        end
        csv << data
      end    
    end  
  end

end
