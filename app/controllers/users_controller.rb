class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:edit, :update, :destroy]

  def index
    @user_count = User.count
    @leaderboard_new = FacilityRevision.count(:id, :group => :user_id, :conditions => 'revision = 1 AND user_id <> 0 AND user_id IS NOT NULL', :order => 'count_id DESC', :limit => 10)
    @leaderboard_edits = FacilityRevision.count(:id, :group => :user_id, :conditions => 'revision <> 1 AND user_id <> 0 AND user_id IS NOT NULL', :order => 'count_id DESC', :limit => 10)
  end

  def show
    @user = User.find(params[:id])
    @revisions = @user.facility_revisions.paginate(:all, :order => 'id DESC', :page => params[:page])
  end

  def new
    @user = User.new
  end

  def edit
    @user = current_user
  end

  def create
    @user = User.new(params[:user])

    if verify_recaptcha(:model => @user) && @user.save
      flash[:success] = 'Registration successful'
      flash[:analytics] = url_for(@user) + '/created'
      cookies[:user_id] = @user.id
      redirect_to welcome_path
    else
      flash[:analytics] = new_user_path + '/validation'
      render :action => "new"
    end
  end

  def update
    @user = current_user

    if @user.update_attributes(params[:user])
      flash[:success] = 'User information successfully updated'
      flash[:analytics] = url_for(@user) + '/created'
      redirect_back_or_default(guidelines_url)
    else
      flash[:analytics] = url_for(@user) + '/updated'
      render :action => "edit"
    end
  end

#TODO something less destructive perhaps?
#  def destroy
#    @user = current_user
#    #@user.destroy

#    redirect_to root_url
#  end

end

