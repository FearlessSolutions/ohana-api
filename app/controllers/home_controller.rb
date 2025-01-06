class HomeController < ApplicationController
  include CurrentLanguage

  def index
    @current_lang = current_language
    @recommended_tags = RecommendedTag.active
    fire_homepage_view_event
  end
end
