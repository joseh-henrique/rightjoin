class PhotosController < ApplicationController
  def index 
    image_set = params[:image_set]
    @photos = Photo.order("created_at desc").where(:image_set => image_set).to_a
    render 'index', :layout => false
  end

  def create
     @photo = Photo.new(params[:photo])
     @photo.save!
  
     render json: {id: @photo.id, title: @photo.title, url: @photo.image.standard.url(:secure => true)}, content_type: 'text/json', status: :ok
     
  rescue Exception => e
    logger.error e
    render :nothing => true, status: :internal_server_error
  end
end
