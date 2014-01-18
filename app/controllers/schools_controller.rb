class SchoolsController < ApplicationController
  include ActionView::Helpers::NumberHelper
  
  respond_to :html, :js, :json
  
  def index
  end
  
  def search
    query = params[:q]
    
    unless query.blank?
      geocoder_results = Geocoder.search(query)
    
      unless geocoder_results.empty?
        geo_location = geocoder_results.first
        @latitude = geo_location.latitude
        @longitude = geo_location.longitude
      end
    else
      @latitude = params[:latitude].to_f
      @longitude = params[:longitude].to_f
    end
    
    # magic numbers (max results 100 schools, 24,140 m ~ 15 miles)
    @schools_and_distance = School.find_schools_near(@latitude, @longitude, 100, 24140) 
    @schools = @schools_and_distance.map(&:first)
    @markers = Gmaps4rails.build_markers(@schools_and_distance) do |school_and_distance, marker|
      school = school_and_distance.first
      distance = number_with_precision(school_and_distance.second * 0.000621371, precision: 2) # meters to miles
      marker.lat school.latitude
      marker.lng school.longitude
      marker.infowindow render_to_string(partial: 'schools/school_marker', locals: { school: school, distance: distance })
      marker.title school.school_id
    end
    
    logger.info "Found #{@schools.size} schools near #{query}"

    respond_to do |format|
      format.js {}
    end
  end

end
