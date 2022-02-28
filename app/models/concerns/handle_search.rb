require 'email_filter'
require 'location_filter'
require 'services_filter'

module HandleSearch
  extend ActiveSupport::Concern

  included do
    def nearbys(radius)
      r = LocationFilter.new(self.class).validated_radius(radius, 0.5)
      super(r)
    end

    scope :category, (lambda do |category|
      joins(services: :categories).where(categories: { name: category })
    end)

    scope :is_near, LocationFilter

    scope :org_name, (lambda do |org|
      joins(:organization).where('organizations.name @@ :q', q: org)
    end)

    scope :with_email, EmailFilter

    scope :filter_by_services, ServicesFilter

    scope :with_taxonomy, (lambda do |ids|
      tax_ids = taxonomy_ids(ids)
      joins(services: :categories).
        where(categories: { taxonomy_id: tax_ids }).
        distinct
    end)
  end

  module ClassMethods
    def status(param)
      param == 'active' ? where(active: true) : where(active: false)
    end

    def keyword(query)
      where("locations.tsv_body @@ plainto_tsquery('english', ?)", query).
        order("#{rank_for(query)} DESC, locations.updated_at DESC")
    end

    def rank_for(query)
      sanitized = ActiveRecord::Base.connection.quote(query)

      <<-RANK
        ts_rank(locations.tsv_body, plainto_tsquery('english', #{sanitized}))
      RANK
    end

    def language(lang)
      where('locations.languages && ARRAY[?]', lang)
    end

    def service_area(service_area_param)
      joins(:services).where('services.service_areas @@ :q', q: service_area_param).distinct
    end

    def text_search(params = {})
      allowed_params(params).to_h.reduce(self) do |relation, (scope_name, value)|
        value.present? ? relation.public_send(scope_name, value) : relation.all
      end
    end

    def taxonomy_ids(ids, skip_descendants = false)
      tax_ids = parse_taxonomy_ids ids
      return tax_ids if skip_descendants

      Category.where(taxonomy_id: tax_ids).map do |cat|
        [cat.taxonomy_id] << cat.descendants.map(&:taxonomy_id)
      end.flatten.uniq
    end

    def parse_taxonomy_ids(ids)
      case ids
      when Array
        ids
      when String
        ids.split(',')
      else
        []
      end
    end

    # def taxonomy_children(taxonomy_id)
    #   parent = Category.find_by_taxonomy_id(taxonomy_id)
    #   parent.descendants.map(&:taxonomy_id)
    # end

    def search(params = {})
      res = text_search(params).
            with_email(params[:email]).
            is_near(params[:location], params[:lat_lng], params[:radius]).
            filter_by_services(params[:categories])

      return res unless params[:keyword] && params[:service_area]
      res.select("locations.*, #{rank_for(params[:keyword])}")
    end

    def search_needs_location(params = {})
      res = with_taxonomy(params[:taxonomy_ids]).
            is_near(params[:location], params[:lat_lng], params[:radius])
      res
    end

    def allowed_params(params)
      params.permit(
        { category: [] }, :category, :keyword, :language, :org_name, :service_area, :status
      )
    end

    def allowed_services_params(params)
      params.permit(
        { categories: [] }, :wait_time, :filters
      )
    end
  end
end
