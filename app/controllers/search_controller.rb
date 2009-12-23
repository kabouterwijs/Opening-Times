class SearchController < ApplicationController
  include Geokit::Geocoders
  include Geokit::Mappable
  include ParserUtils

  DISTANCES = [1, 2, 5, 10, 15, 20, 50]
  DISTANCE_DEFAULT = 15
  RESULTS_PER_PAGE = 10
  RESULTS_LIMIT = 30

  def index
    return kml if "kml" == params[:format]
    @location = GeocodeCache.geocode(params[:location])
    
    if @location
      set_distance
      @facilities = Facility.paginate(:all, :origin => @location, :within => @distance, :order => 'distance', :page => params[:page], :per_page => RESULTS_PER_PAGE)
      @status_manager = StatusManager.new      
    else
      render 'no_results'
    end
  end

  def kml
    bounds = params["BBOX"].to_s.split(",")
    @facilities = []
    @status_manager = StatusManager.new      
    if 4 == bounds.size
      sw = GeoKit::LatLng.new(bounds[1],bounds[0])
      ne = GeoKit::LatLng.new(bounds[3],bounds[2])
      bounds = GeoKit::Bounds.new(sw,ne)
      @facilities = Facility.find(:all, :bounds => bounds, :limit => 10)
    else
      @facilities = Facility.find(:all, :limit => 10)
    end
  end
    
  private

  def set_distance
    @distance = params[:distance].to_i
    @distance = DISTANCE_DEFAULT unless DISTANCES.include?(@distance)
  end  

end

