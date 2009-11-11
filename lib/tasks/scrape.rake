namespace :scrape do

  task(:data => [:environment]) do
    facility_name = ENV['facility']
    file_name = "../scrapers/lib/scraper/#{facility_name.downcase}_scraper.rb"
    if facility_name.blank? || !File.exists?(file_name)
      puts "Please specify which facility you wish to scrape\n#{file_name} not found"
      Process.exit
    end
    require file_name
    class_name = facility_name.titlecase.gsub('-','')
    puts "Scraping #{class_name}"
    Module.const_get("#{class_name}Scraper").new
  end

end

