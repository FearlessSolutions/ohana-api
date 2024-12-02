class LocationsController < ApplicationController
  include Cacheable

  def index
    # To enable Google Translation of keywords,
    # uncomment lines 8-9, and see documentation for
    # GOOGLE_TRANSLATE_API_KEY in config/application.example.yml.
    # translator = KeywordTranslator.new(params[:keyword], current_language, 'en')
    # params[:keyword] = translator.translated_keyword
    puts "request params", params
    
    search_params = process_request
    # initialize_search_parameters
    # search_params = process_search_params(params.dup)
    # search_params.delete_if { |key, value| key == "button" }
puts "search_params", search_params
    # Performs the actual search using the processed search parameters above
    set_coordinates
# puts "sent matched_category", @matched_category.name if @matched_category
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
    @search = Search.new(locations, params)


    # additional params for the view based on the user inputs in the search menu
    @keyword = params[:keyword]
    @lat = params[:lat]
    @long = params[:long]
    @address = params[:address]
    @languages = Location.active_languages
    @selected_language = params[:languages]&.first
    @address = 'Current Location' if @address.nil? && @lat.present? && @long.present?
    @selected_distance_filter = params[:distance]

    @main_category_selected_name = search_params[:main_category] if @matched_category
    @selected_categories = params[:categories] || []
    puts "selected categories", @selected_categories
    @keyword_matched_category = @matched_category.present? && params[:keyword].present?
    puts "@keyword_matched_category", @keyword_matched_category
    @clear_categories = params[:keyword].present? && !@matched_category
    puts "@clear_categories", @clear_categories

    @exact_match_found = @locations_search.exact_match_found?
puts " @main_category_selected_name final", @main_category_selected_name
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
    puts "URL", @url
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
    puts "Step 1"
    puts "is_new_search?", is_new_search?
    #  if #keyword-search-button is entered, all filters are cleared and a new keyword search is done
    if is_new_search?
      puts "Step 2"
      @main_category_selected_name = ""
      @main_category_selected_id = ""

      set_new_search_params
    else
      puts "not new search - just apply or remove filters"
      set_filters
    end
    puts "params after processing", params
    params
  end

  def set_filters
    # @main_category_selected_name = params[:main_category]
    # if @main_category_selected_name.present?
    #   @main_category_selected_id = helpers.get_category_id_by_name(@main_category_selected_name)
    # end

    set_main_category_params
    set_subcategories_params

    puts "filter params", params
    params
  end

  def set_new_search_params
    puts "Step 3"
    puts "params[:keyword]", params[:keyword]
    # if a keyword is present in a new search, reset all categories
    if params[:keyword].present?
      puts "Step 4"
      params[:categories] = []
      params[:main_category] = ""
      params[:category_ids] = []
      @main_category_selected_name = ""
      @main_category_selected_id = nil

      # check if the keyword(s) match an existing category or subcategory
      @matched_category = match_keyword_to_subcategory(params[:keyword])
      puts "matched_category", @matched_category
    else
      @matched_category = nil
    end

    # set the category and subcategory parameters (if any) for a new search
    set_category_params

    params
  end

  def set_category_params
    puts "Step 5"
    set_main_category_params
puts "Step 9"
    if @matched_category && @matched_category.parent&.name.present?
      puts "here"
      set_subcategories_params
    end

    params
  end

  def set_main_category_params
    puts "Step 6"
    puts "hello", params
    return if params[:main_category].blank? && @matched_category.nil?
puts "Step 7"
    if @matched_category
      puts "Step 8"
      @main_category_selected_name = @matched_category.parent&.name || @matched_category.name
      @main_category_selected_id = @matched_category.parent&.id || @matched_category.id
      params[:main_category] = @main_category_selected_name
      params[:categories] = [@matched_category.name]
      params[:category_ids] = [@matched_category.id]

      puts "params on matched category", params
    elsif params[:main_category].present?
      puts "now here"
      @main_category_selected_name = params[:main_category]
      @main_category_selected_id = helpers.get_category_id_by_name(@main_category_selected_name)
      params[:category_ids] = [@main_category_selected_id]
    end

    puts "@main_category_selected_name!!", @main_category_selected_name
    puts "params[:main_category]", params[:main_category]
    params
  end

  def set_subcategories_params
    puts "subcategories params", params
    puts "Step 10"

    return if params[:categories].blank? && @main_category_selected_id.blank?
puts "Step 11"
    if params[:categories].present?
      puts "params[:categories]", params[:categories], @main_category_selected_id
      subcategory_ids = helpers.get_subcategories_ids(params[:categories], @main_category_selected_id)
      puts "subcategory_ids", subcategory_ids
      params[:category_ids] = subcategory_ids
    elsif @main_category_selected_id.present?
      params[:category_ids] = [@main_category_selected_id]
    end

    params
  end

  def is_new_search?
    if params[:source] == "homepage"
      return true
    elsif params[:form]
      return true
    end

    false
  end

  def initialize_search_parameters
    @main_category_selected_name = ""
    @main_category_selected_id = ""
    process_main_category
    process_subcategories
  end

  # processes the main category selection from the params
  def process_main_category
    return if params[:main_category].blank?
    return unless validate_category

    # if #keyword-search-button is entered, all filters are cleared and a new keyword search is done
    if params[:button]
      params[:main_category] = ""
      params[:categories] = []
    else
      @main_category_selected_name = params[:main_category]
      @main_category_selected_id = helpers.get_category_id_by_name(@main_category_selected_name)
      params[:main_category_id] = @main_category_selected_id
    end
    puts "params 2", params
    params
  end

  def process_subcategories
    puts "@main_category_selected_name", @main_category_selected_name
    return if params["categories"].blank? && @main_category_selected_id.blank?

    if params["categories"].present?
      subcategory_ids = helpers.get_subcategories_ids(params[:categories], @main_category_selected_id)
      params["category_ids"] = subcategory_ids
    elsif @main_category_selected_id.present?
      params["category_ids"] = [@main_category_selected_id]
    end
  end

  def process_search_params(search_params)
    puts "params 1", params, search_params
    @matched_category = match_keyword_to_subcategory(search_params[:keyword])
    puts "params 2", search_params
    puts "Categ name"
    puts @matched_category.name, @matched_category.parent&.name if @matched_category

    if @matched_category && @main_category_selected_name.blank?
      handle_matched_category(search_params)
    elsif @matched_category.nil?
      handle_unmatched_category(search_params)
    end

    search_params
  end


  def handle_matched_category(search_params)
    if search_params[:source] == "homepage" || search_params[:button]
      search_params[:categories] = [@matched_category.id]
      search_params[:main_category] = @matched_category.parent&.name || @matched_category.name
      @main_category_selected_name = search_params[:main_category]
      @main_category_selected_id = @matched_category.parent&.id || @matched_category.id
      puts "@main_category_selected_name!!!!", @main_category_selected_name
      search_params[:category_ids] = [@matched_category.id]
    elsif search_params[:source] == "filters"
      set_main_category(search_params, @matched_category)
    end
    search_params
  end

  def handle_unmatched_category(search_params)
    puts "unmatched category", search_params[:source]
    if search_params[:keyword].present? && search_params[:source] == "homepage"
      search_params[:categories] = []
      search_params[:main_category] = ""
      @main_category_selected_name = ""
      @main_category_selected_id = nil
      search_params[:category_ids] = []
    else
      set_main_category(search_params)
      process_category_params(search_params)
    end
  end

  def clear_category_params(search_params)
    search_params[:main_category] = ""
    params[:categories] = []
  end

  def set_main_category(search_params, matched_category = nil)
    @main_category_selected_name = search_params[:main_category]
    @main_category_selected_id = helpers.get_category_id_by_name(@main_category_selected_name) if @main_category_selected_name.present?
    search_params["categories"] = [@main_category_selected_id] if @main_category_selected_id.present?
  end

  def process_category_params(search_params)
    if search_params["categories"].present?
      search_params["category_ids"] = helpers.get_subcategories_ids(search_params["categories"], @main_category_selected_id)
    elsif @main_category_selected_id.present?
      search_params["category_ids"] = [@main_category_selected_id]
    end
  end

  # exact keyword search match with subcategory
  def match_keyword_to_subcategory(keyword)
    return nil if keyword.blank?

    Category.where("LOWER(name) = ?", keyword.downcase).first
  end
end
