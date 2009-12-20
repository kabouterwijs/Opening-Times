class SearchController < ApplicationController
  include Geokit::Geocoders
  include Geokit::Mappable
  include ParserUtils

  DISTANCES = [1, 2, 5, 10, 15, 20, 50]
  DISTANCE_DEFAULT = 15
  RESULTS_PER_PAGE = 10
  RESULTS_LIMIT = 30

# if no params then render nothing found
# if @t then find group
# if groups then render choose group
# if !groups then render nothing found
# lat, lng = get_from_lat_lat(q)
# find_service by_ lat lng (and group)
# if no services then render nothing found
#

  def index
    @location = params[:location]
    @group = params[:group]

    respond_to do |format|
      format.html do
        if @location.blank? && !@group.blank?
          search_groups
        elsif @location.blank? && @group.blank?
          render 'no_results' and return
        else
          search
        end
      end
      format.json { search }
      format.xml { search }
      format.kml { kml }
    end
  end

  private

  def kml
    
    bounds = params["BBOX"].to_s.split(",")
    if 4 == bounds.size
      sw = GeoKit::LatLng.new(bounds[1],bounds[0])
      ne = GeoKit::LatLng.new(bounds[3],bounds[2])
      bounds = GeoKit::Bounds.new(sw,ne)
      @facilities = Facility.find(:all, :bounds => bounds, :limit => 20)
    else
      render "network.kml"
    end
  end

  def search
    unless @group.blank?
      search_groups
      return unless @filter_group
    end

    render 'no_results' and return if @location.blank?

    l_lat, l_lng = extract_lat_lng(@location)
    logger.info "lat=#{l_lat}, lng=#{l_lng}"
    if l_lat && l_lng
      @location = Geokit::LatLng.new(l_lat, l_lng)
    else
      logger.info "geocoding"
      @location = MultiGeocoder.geocode(@location) # + ", UK") # removing the UK, as it always returns a result otherwise
      render 'no_results' and return unless @location.success
    end

    @distance = params[:distance].to_i
    @distance = DISTANCE_DEFAULT unless DISTANCES.include?(@distance)

    if @filter_group
      @facilities = Facility.paginate(:all, :origin => @location, :within => @distance, :conditions=>["id IN (SELECT facility_id FROM group_memberships WHERE group_id = ?)", @filter_group.id], :order => 'distance', :page => params[:page], :per_page => RESULTS_PER_PAGE)
    else
      @facilities = Facility.paginate(:all, :origin => @location, :within => @distance, :order => 'distance', :page => params[:page], :per_page => RESULTS_PER_PAGE)
    end

    @status_manager = StatusManager.new

    render 'no_results' and return if @facilities.empty?

    respond_to do |format|
      format.html
      format.xml
      format.json
    end
  end

  def search_groups
    if @filter_group = Group.find_by_slug(@group.slugify)
      if @location.blank?
        redirect_to(@filter_group) and return
      else
        return
      end
    else
      @matches = [] #Group.find_by_sql(["SELECT name, slug FROM groups WHERE slug SOUNDS LIKE ?", @group.slugify])
#      render :template => "groups/not_found", :status => 404 and return
      render :template => "search/choose_group", :status => 404 and return
    end
  end

#  def find_filter_group
#    unless @filter_group = Group.find_by_slug(@group.slugify)
#      @matches = Group.find_by_sql(["SELECT name, slug FROM groups WHERE slug SOUNDS LIKE ?", @group.slugify])
#      render :template => "search/choose_group", :status => 404 and return
#    end
#  end

end

