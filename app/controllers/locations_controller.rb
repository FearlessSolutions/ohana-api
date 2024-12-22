class LocationsController < ApplicationController
  include Cacheable

  def index
    # To enable Google Translation of keywords,
    # uncomment lines 8-9, and see documentation for
    # GOOGLE_TRANSLATE_API_KEY in config/application.example.yml.
    # translator = KeywordTranslator.new(params[:keyword], current_language, 'en')
    # params[:keyword] = translator.translated_keyword

    search_params = process_request

    # Performs the actual search using the processed search parameters above
    set_coordinates
    @locations_search = LocationsSearch.new(
      accessibility: search_params[:accessibility],
      main_category_name: @main_category_selected_name,
      category_ids: search_params[:category_ids],
      distance: search_params[:distance],
      keywords: search_params[:keyword],
      lat: @lat,
      long: @lon,
      org_name: search_params[:org_name],
      tags: search_params[:tags],
      zipcode: search_params[:location],
      page: search_params[:page],
      per_page: search_params[:per_page],
      languages: search_params[:languages],
      matched_category: @matched_category
    )
    locations = @locations_search.search.load&.objects
    @search = Search.new(locations, search_params)


    # additional params for the view based on the user inputs in the search menu
    @keyword = search_params[:keyword]
    @lat = search_params[:lat]
    @long = search_params[:long]
    @address = search_params[:address]
    @languages = Location.active_languages
    @selected_language = search_params[:languages]&.first
    @address = 'Current Location' if @address.nil? && @lat.present? && @long.present?
    @selected_distance_filter = search_params[:distance]

    @main_category_selected_name = search_params[:main_category]
    @selected_categories = search_params[:categories] || []
    @keyword_matched_category = @matched_category.present? && search_params[:keyword].present?
    @clear_categories = search_params[:keyword].blank? && @main_category_selected_name.blank?

    @exact_match_found = @locations_search.exact_match_found?

    # caches the search results and renders the view
    cache_page(@search.locations) if @search.locations.present?

    respond_to do |format|
      format.html do
        if params[:layout] == "false"
          render template: 'component/locations/results/_body', locals: { search: @search }, layout: false
        else
          render
        end
      end
    end

  end

  def show
    id = params[:id].split('/').last
    @location = Location.get(id)
    fire_location_view_event

    if current_user.present?
      @current_user = current_user
      @current_user_id = current_user.id
      @favorite = current_user.favorites.any? do |f|
        f.resource_id == @location.id && f.resource_type == 'location'
      end
    else
      @favorite = false
      @current_user_id = 0
    end

    @categories = @location.services.map { |s| s[:categories] }.flatten.compact.uniq

    request.query_parameters["layout"] = true
    @query_parameters = request.query_parameters
    @url = request.url
  end

  # Ajax response to update the exanded div listing subcategories
  def get_subcategories_by_category
    permitted = params.permit(:category_name)
    category_name = permitted["category_name"]

    category_id = helpers.get_category_id_by_name(category_name)
    sub_cat_array = helpers.subcategories_by_category(category_id)

    respond_to do |format|
      format.json { render json: { sub_cat_array: sub_cat_array, category_title: helpers.category_filters_title(category_name) } }
      format.js { render json: { sub_cat_array: sub_cat_array, category_title: helpers.category_filters_title(category_name) } }
    end
  end

  def validate_category
    return helpers.main_categories_array.map{|row| row[0] }.include?(params[:main_category])
  end

  def set_coordinates
    address = params[:address]
    if address.present? && address != "Current Location"
      response = Geocoder.search(params[:address])
      unless response.empty?
        coordinates = response.first.data['geometry']['location']
        @lat = coordinates['lat']
        @lon = coordinates['lng']
      end
    elsif params[:lat].present? && params[:long]
      @lat = params[:lat]
      @lon = params[:long]
    end
  end

  private

  def process_request
    @main_category_selected_name = ""
    @main_category_selected_id = ""

    if is_new_search?
      set_new_search_params
    else
      set_filters
    end

    params
  end

  def set_filters
    set_main_category_params
    set_subcategories_params

    params
  end

  def is_new_search?
    # a new search is performed when searching from the homepage or
    # from the search button in the side search bar
    if params[:source] == "homepage" || params[:button]
      return true
    end

    false
  end

  def set_new_search_params
    # reset main category if a new search request comes from the side bar
    params[:main_category] = "" if params[:source] == "side_bar"

    # if a keyword is present in a new search, reset all categories
    if params[:keyword].present?
      params[:categories] = []
      params[:main_category] = ""
      params[:category_ids] = []
      @main_category_selected_name = ""
      @main_category_selected_id = nil

      # check if the keyword(s) match an existing category or subcategory
      @matched_category = match_keyword_to_subcategory(params[:keyword])
    else
      @matched_category = nil
    end

    # set the category and subcategory parameters (if any) for a new search
    set_category_params

    params
  end

  def set_category_params
    set_main_category_params

    # if a subcategory was matched, set the subcategories as well
    if @matched_category && @matched_category.parent&.name.present?
      set_subcategories_params
    end

    params
  end

  def set_main_category_params
    return if params[:main_category].blank? && @matched_category.nil?

    # if the keyword(s) matched a category/subcategory, set the main category and
    # any applicable subcategories accordingly
    if @matched_category
      @main_category_selected_name = @matched_category.parent&.name || @matched_category.name
      @main_category_selected_id = @matched_category.parent&.id || @matched_category.id
      params[:main_category] = @main_category_selected_name
      params[:categories] = [@matched_category.name]
      params[:category_ids] = [@matched_category.id]

    ## otherwise, use the selected main category, if present
    elsif params[:main_category].present?
      @main_category_selected_name = params[:main_category]
      @main_category_selected_id = helpers.get_category_id_by_name(@main_category_selected_name)
      params[:category_ids] = [@main_category_selected_id]
    end

    return unless validate_category

    params
  end

  def set_subcategories_params
    return if params[:categories].blank? && @main_category_selected_id.blank?

    if params[:categories].present?
      subcategory_ids = helpers.get_subcategories_ids(params[:categories], @main_category_selected_id)
      params[:category_ids] = subcategory_ids
    elsif @main_category_selected_id.present?
      params[:category_ids] = [@main_category_selected_id]
    end

    params
  end

  # exact keyword search match with subcategory
  def match_keyword_to_subcategory(keyword)
    return nil if keyword.blank?

    Category.where("LOWER(name) = ?", keyword.downcase).first
  end
end