namespace :scrape do

  task(:data => [:environment]) do
    facility_name = ENV['facility']
    if facility_name.blank?
      puts "Please specify which facility you wish to scrape"
      Process.exit
    end
    puts "Scraping #{facility_name.titlecase}"
    require "../scrapers/lib/scraper/#{facility_name.downcase}_scraper.rb"
    Module.const_get("#{facility_name}Scraper").new
  end

end

