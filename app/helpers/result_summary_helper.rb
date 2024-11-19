module ResultSummaryHelper
  extend ActionView::Helpers::TextHelper
  PARAMS_FRIENDLY_NAME = {
    "main_category" => "Topic",
    "keyword" => "Keyword"
  }

  def search_results_page_title
    if search_params_present?
      search_terms = request.query_parameters.except(:utf8).
                     map { |k, v| "#{PARAMS_FRIENDLY_NAME[k]}: #{v}" if v.present? }.
                     compact.join(', ')
      "Search results for: #{search_terms}"
    else
      "All Results"
    end
  end

  def search_params_present?
    request.query_parameters.values.reject(&:blank?).present?
  end

  # Formats map result summary text
  # @return [String] Result summary string for display on search results view.
  def map_summary
    total_results = @search.locations.size
    total_map_markers = @search.map_data.size
    summary = if total_map_markers == total_results
                ''
              else
                " <i class='fa fa-map-marker' aria-label='location marker' role='img' tabindex='0'></i> <em>"\
                "#{total_map_markers}/#{total_results} "\
                "located on map</em>"
              end
    summary.html_safe
  end

  def location_link_for(location)
    if location.organization.name == location.name
      location_path([location.slug], request.query_parameters)
    else
      location_path([location.organization.slug, location.slug], request.query_parameters)
    end
  end

  def service_id_for(service_name)
    service_name.split("(").first.split(" ").join("")
  end
end
