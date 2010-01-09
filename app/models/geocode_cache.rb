class GeocodeCache < ActiveRecord::Base
  include Geokit::Geocoders

  acts_as_mappable :default_units => :miles, :default_formula => :flat

  validates_presence_of :location
  validates_numericality_of :lat, :greater_than_or_equal_to => -90, :less_than_or_equal_to => 90
  validates_numericality_of :lng, :greater_than_or_equal_to => -180, :less_than_or_equal_to => 180

  def before_save
    self.location = self.location.slugify
  end

  def self.find_by_location(location)
    self.find(:first, :conditions => { :location => location.slugify } )
  end

  def self.geocode(q)
    return false if q.blank?
    query_is_lat_lng(q) || find_by_location(q) || geocode_query(q)
  end

  private

  def self.query_is_lat_lng(q)
    lat, lng = ParserUtils.extract_lat_lng(q)
    if lat && lng
      Geokit::LatLng.new(lat, lng)
    else
      false
    end
  end

  def self.geocode_query(q)
    location = MultiGeocoder.geocode(q, :bias => "UK")
    
    if location.success && %w(UK GB IM JE GG IE).include?(location.country_code)
      GeocodeCache.create(:location => q, :lat => location.lat, :lng => location.lng) rescue logger.warn("GeocodeCache clash")
      return location
    else
      false
    end  
  end




end

