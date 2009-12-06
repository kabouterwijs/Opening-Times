require 'progressbar'
require 'csv'

namespace :export do

  desc "Run all single file exports"
  task(:all => [:mysql, :csv, :xml])

  desc "Export facility as one xml file (gzip)"
  task(:xml => [:environment]) do
    file_path = "#{RAILS_ROOT}/public/export/facilities.xml"
    progress = ProgressBar.new("Exporting XML", Facility.count)

    File.open(file_path,"w") do |file|
      xml = Builder::XmlMarkup.new(:indent => 2, :target => file)
      xml.instruct!
      xml.comment! "The Opening Times http://opening-times.co.uk data are made available under the Open Database License: http://opendatacommons.org/licenses/odbl/1.0/. Any rights in individual contents of the database are licensed under the Database Contents License: http://opendatacommons.org/licenses/dbcl/1.0/. "

      xml.facilities do
        Facility.find(:all, :include => [ :normal_openings, :holiday_openings, :groups]).each do |facility|
          facility.to_xml(:builder => xml, :skip_instruct => true)
          progress.inc
        end
      end
    end
   `gzip -f -c -9 #{file_path} > #{file_path}.gz`
    progress.finish
  end

  desc "Export facility as one xml file per facility (not included in :all)"
  task(:xml_files => [:environment]) do
    facilities = Facility.all

    if facilities.empty?
      puts "No facilties" and return
    end

    Dir.glob("export/*").each do |file|
      File.delete(file)
    end

    progress = ProgressBar.new("Exporting", facilities.size)
    facilities.each do |facility|
      File.open("#{facility.slug}.xml", "w") do |file|
        progress.inc
        file << facility.to_xml
      end
    end
    progress.finish
  end

  desc "Export facility as one csv file (gzip)"
  task(:csv => :environment) do
    file_path = "#{RAILS_ROOT}/public/export/facilities.csv"
    progress = ProgressBar.new("Exporting CSV", Facility.count)

    CSV.open(file_path,"w") do |csv|
      csv << ["The Opening Times http://opening-times.co.uk data are made available under the Open Database License: http://opendatacommons.org/licenses/odbl/1.0/. Any rights in individual contents of the database are licensed under the Database Contents License: http://opendatacommons.org/licenses/dbcl/1.0/. "]

      csv << ["id","name","location","address","postcode","latitude","longitude","phone","url","tags","Mon","Tue","Wed","Thu","Fri","Sat","Sun","Bank Holidays"]
      Facility.find(:all, :include => [ :normal_openings, :holiday_openings, :groups]).each do |facility|

        counter = 0
        data = []
        data << facility.id
        data << facility.name
        data << facility.location
        data << facility.address
        data << facility.postcode
        data << facility.lat
        data << facility.lng
        data << facility.phone
        data << facility.url
        data << facility.groups_list

        [1,2,3,4,5,6,0].each do |day| # Each day of the week
          day_data = []
          facility.normal_openings.sort.each do |opening|
            if opening.wday == day # if the opening is for this day
              counter += 1
              day = opening.summary
              day += "; #{opening.comment}" unless opening.comment.blank?
              day_data << day
              opening = facility.normal_openings[counter]
            end
          end
          day_data << "Closed" if day_data.empty?
          data << day_data.join("\r\n")
        end

        holiday_data = []
        facility.holiday_openings.each do |holiday_opening|
          holiday_data << holiday_opening.summary
        end
        data << holiday_data.join("\r\n")

        csv << data
        progress.inc
      end
    end
    `gzip -f -c -9 #{file_path} > #{file_path}.gz`
    progress.finish
  end

  desc "MySqlDump all tables except user (gzip)"
  task(:mysql => :environment) do
    file_path = "#{RAILS_ROOT}/public/export/facilities.sql"
    File.open(file_path,"w") do |f|
      f << "-- The Opening Times http://opening-times.co.uk data are made available under the Open Database License: http://opendatacommons.org/licenses/odbl/1.0/. Any rights in individual contents of the database are licensed under the Database Contents License: http://opendatacommons.org/licenses/dbcl/1.0/. "
    end

    database, user, password = retrieve_db_info

    cmd = "/usr/bin/env mysqldump --opt --skip-add-locks -u#{user} --ignore-table=#{database}.users "
    puts cmd + "... [password filtered]"
    cmd += " -p'#{password}' " unless password.nil?
    cmd += " #{database} >> #{file_path}"
    result = system(cmd)
    `gzip -f -c -9 #{file_path} > #{file_path}.gz`
  end

end

