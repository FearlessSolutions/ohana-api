module ApplicationHelper

  TODAY = Date.current.to_time(:utc).beginning_of_day

  def version
    @version ||= File.read('VERSION').chomp
  end

  def last_updated_at(updated_at)
    last_updated_text = '<p>Last Updated: ' + (updated_at ? updated_at.strftime('%m/%d/%Y, %l:%M %p') : 'N/A') + '</p>'
    last_updated_text.html_safe
  end

  def number_of_updates(location_id)
    total = number_of_updates_past_thirty_days(location_id)
    updates = '<p>Updates in the past month: ' + "#{total}" + '</p>'
    updates.html_safe
  end

  def number_of_updates_past_thirty_days(location_id)
    past_thirty_days = ((TODAY - 30.days)..TODAY.end_of_day)
    Ahoy::Event.where(name: 'Location Update', properties: {id: "#{location_id}"}, time: past_thirty_days).count
  end

  def number_of_visits(location_id)
    visits = ""
    date_ranges = get_date_range_options
    number_visits_per_date_range = get_visits_per_date_range(location_id)

    number_visits_per_date_range.each_with_index do |total, i|
      visits << "<li>#{date_ranges[i]}: #{total}</li>"
    end

    visits.html_safe
  end

  def get_date_range_options
    ['Yesterday', 'Last 7 Days', 'Last 30 Days', 'Last Month', 'Last Quarter', 'Last 12 Months']
  end

  def get_visits_per_date_range(location_id)
    intervals = create_date_ranges
    times_visited = []
    intervals.each do |interval|
      times_visited <<
      Ahoy::Event.where(name: 'Location Visit', properties: {id: "#{@location.id}"}, time: interval).count
    end
    times_visited
  end

  def create_date_ranges
    yesterday_end = Date.yesterday.to_time(:utc).end_of_day

    date_ranges = get_date_range_options
    intervals = []

    date_ranges.each do |date_range|
      case date_range
      when 'Yesterday'
        intervals << (Date.yesterday.to_time(:utc).beginning_of_day..yesterday_end)
      when 'Last 7 Days'
        intervals << ((TODAY - 7.days)..TODAY.end_of_day)
      when 'Last 30 Days'
        intervals << ((TODAY - 30.days)..TODAY.end_of_day)
      when 'Last Month'
        last_month = TODAY.prev_month
        intervals << (last_month.beginning_of_month..last_month.end_of_month)
      when 'Last Quarter'
        prev_quarter = TODAY.prev_quarter
        intervals << (prev_quarter.beginning_of_quarter..prev_quarter.end_of_quarter)
      when 'Last 12 Months'
        intervals << ((TODAY.prev_year)..TODAY.end_of_day)
      end
    end

    intervals

  end

  def upload_server
    Rails.configuration.upload_server
  end

  # Appends the site title to the end of the page title.
  # The site title is defined in config/settings.yml.
  # @param page_title [String] the page title from a particular view.
  def title(page_title)
    site_title = SETTINGS[:site_title]
    if page_title.present?
      content_for :title, "#{page_title} | #{site_title}"
    else
      content_for :title, site_title
    end
  end

  # Since this app includes various parameters in the URL when linking to a
  # location's details page, we can end up with many URLs that display the
  # same content. To gain more control over which URL appears in Google search
  # results, we can use the <link> element with the 'rel=canonical' attribute.

  # This helper allows us to set the canonical URL for the details page in the
  # view. See app/views/locations/show.html.haml
  #
  # More info: https://support.google.com/webmasters/answer/139066
  def canonical(url)
    content_for(:canonical, tag(:link, rel: :canonical, href: url)) if url
  end

  # This is the list of environment variables found in config/application.yml
  # that we wish to pass to JavaScript and access through the interface in
  # assets/javascripts/util/environmentVariables.js
  def environment_variables
    raw({
      DOMAIN_NAME: ENV['DOMAIN_NAME']
    }.to_json)
  end

  def cache_key_for(hash)
    Digest::MD5.hexdigest(hash.to_s)
  end

  # Render Markdown
  # Returns html from markdown string
  # @params {string} content - a block of markdown or string to format
  # @return {string} html
  def render_markdown(content)
    markdown = Redcarpet::Markdown.new(Redcarpet::Render::HTML,
                                       no_intra_emphasis: true,
                                       fenced_code_blocks: true,
                                       disable_indented_code_blocks: true,
                                       autolink: true,
                                       tables: true,
                                       underline: true,
                                       highlight: true,
                                       hard_warp: true
                                      )
    return markdown.render(content).html_safe
  end

  ## Decode JSON
  def decode_json(value)
    ActiveSupport::JSON.decode(value)
  end
end
