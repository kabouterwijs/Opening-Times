class AboutController < ApplicationController

  caches_page :homepage, :sitemap #

  def bankholidays
    @holiday_sets = HolidaySet.all
    respond_to do |format|
      format.xml { render :xml => @holiday_sets.to_xml( :include=>:holiday_events ) }
      format.json { render :json => @holiday_sets.to_json( :include=>:holiday_events ) }
      format.html
    end
  end

  def recentchanges
    respond_to do |format|
      format.html {
        @revisions = FacilityRevision.find(:all, :select => 'id, facility_id, length, slug, comment, revision, user_id, ip, created_at', :order => 'id DESC', :limit => 100)
      }
      format.xml {
        @facilities = Facility.find(:all, :select => 'id, name, location, slug, comment, created_at',  :order => 'updated_at DESC', :limit => 100)
      }
      format.rss { redirect_to :format => :xml }
    end
  end

  def recentlyremoved
    @removed = Facility.find(:all, :conditions => "retired_at IS NOT NULL", :order => 'id DESC', :limit => 100)
    render :text => "Nothing has been removed" and return if @removed.empty?
    respond_to do |format|
      format.html
      format.xml
      format.rss { redirect_to :format => :xml }
    end
  end

  def register
    redirect_to signup_path
  end

  def sitemap
    @facilities = Facility.paginate(:all, :select => 'slug, updated_at', :page => params[:page])
  end

  def statistics
    @status_manager = StatusManager.new

    @total_facilities = Facility.count
    @total_active_facilities = Facility.count(:conditions => "retired_at IS NULL")
    @new_facilities_today = Facility.count(:id, :conditions => ["created_at > ?", Date.today])
    @total_open = @status_manager.open_size
    @percent_open = (100 * (@total_open.to_f / @total_active_facilities)).round


    @total_users = User.count
    @new_users_today = User.count(:id, :conditions => ["created_at > ?", Date.today])
  end

end

