class AdsController < ApplicationController
  load_and_authorize_resource
  before_action :require_admin

  def require_admin
    if not Setting.admin_emails.include?(current_user.email)
      render_404
    end
  end

  def index
    @ads = Ad.all
  end

  def new
    @topic = Topic.find_by_id(params[:topic_id])
    render_404 if @topic.blank?
    @ad = Ad.new
    @ad.topic_id = @topic.id
    @ad.topic_title = @topic.title
    @ad.topic_author = @topic.user.login
  end

  def edit
    @ad = Ad.find(params[:id])
  end

  def create
    @ad = Ad.new(ad_params)
    if @ad.save
      redirect_to(ads_path, notice: 'Ad was successfully created.')
    else
      render action: "new"
    end
  end

  def update
    @ad = Ad.find(params[:id])

    if @ad.update_attributes(ad_params)
      redirect_to(ads_path, notice: 'Ad was successfully updated.')
    else
      render action: "edit"
    end
  end

  def destroy
    @ad = Ad.find(params[:id])
    @ad.destroy

    redirect_to(ads_url)
  end

  protected

  def ad_params
    params.require(:ad).permit(:cover, :topic_id, :topic_title,:topic_author)
  end
end
