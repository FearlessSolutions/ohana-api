module ApplicationHelper
  def version
    @version ||= File.read('VERSION').chomp
  end

  def last_updated_at(updated_at)
    last_updated_text = '<p>Last Updated: ' + (updated_at ? updated_at.strftime('%m/%d/%Y, %l:%M %p') : 'N/A') + '</p>'
    last_updated_text.html_safe
  end

  def number_of_visits(location_id)
    visit_html_list = ""
    date_ranges = AhoyQueries::DATE_RANGE_OPTIONS

    date_ranges.each do |date_range|
      visits_per_date_range = AhoyQueries.get_total_visits_by_location_and_date_range(location_id, date_range)
      visit_html_list << "<li>#{date_range}: #{visits_per_date_range}</li>"
    end

    visit_html_list.html_safe
  end

  def number_of_updates(location_id)
    updates_last_thirty_days = AhoyQueries.get_number_of_updates_last_thirty_days(location_id)
    updates = '<p>Updates in the last 30 days: ' + "#{updates_last_thirty_days}" + '</p>'
    updates.html_safe
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
