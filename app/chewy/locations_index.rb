# frozen_string_literal: true
class LocationsIndex < Chewy::Index
  settings analysis: {
    analyzer: [
      {
        remove_stop_words: {
          type: "standard",
          stopwords: "_english_"
        }
      },
      {
        case_insensitive: {
          "tokenizer": "keyword",
          "filter": "lowercase"
        }
      }
    ]
  }

  index_scope Location.includes(:address, services: [:categories, :tags], organization: :tags)

  field :accessibility
  field :archived, type: 'boolean', value: -> { !archived_at.nil? } 
  field :archived_at, value: -> { archived_at? ? archived_at : nil }, type: 'date'
  field :categories, value: -> { services.map(&:categories).flatten.uniq.map(&:name) }
  field :categories_exact, analyzer: 'case_insensitive', value: -> { services.flat_map(&:categories).select { |cat| cat.ancestry.blank? }.uniq.map(&:name) }
  field :category_ids, value: -> { services.map(&:categories).flatten.uniq.map(&:id) }
  field :coordinates, type: 'geo_point', value: -> do
    if latitude? && longitude?
      {lat: latitude, lon: longitude}
    else
      nil
    end
  end
  field :covid19, value: -> { covid19? ? created_at : nil }, type: 'date'
  field :created_at, type: 'date'
  field :description, analyzer: 'remove_stop_words'
  field :featured_at, type: 'date'
  field :id, type: 'integer'
  field :keywords, value: -> { services.map(&:keywords).compact.join(', ') }, analyzer: 'remove_stop_words'
  field :name, type: 'text', analyzer: 'remove_stop_words'
  field :name_exact, analyzer: 'case_insensitive', value: -> { name }
  field :organization_id, type: 'integer'
  field :organization_name, value: -> { organization.try(:name) }, analyzer: 'remove_stop_words'
  field :organization_name_exact, analyzer: 'case_insensitive', value: -> { organization.try(:name) }
  field :organization_tags, value: -> { organization.tags.pluck(:name) }
  field :service_descriptions, value: ->{ services.map(&:description) }
  field :service_names, value: ->{ services.map(&:name) }
  field :service_tags, value: -> { services.map(&:tags).flatten.uniq.map(&:name) }
  field :sub_categories_exact, analyzer: 'case_insensitive', value: -> { services.flat_map(&:categories).select { |cat| !cat.ancestry.blank? }.uniq.map(&:name) }
  field :tags, value: -> { tags.map(&:name) }
  field :updated_at, type: 'date'
  field :zipcode, value: -> { address.try(:postal_code) }
  field :languages, type: 'keyword', value: -> { services.map(&:languages).concat(languages).flatten.uniq.reject(&:blank?) }
  field :open_flags, type: 'integer', value: -> {Flag.where(resource_id: id, completed_at: nil, resource_type: "Location").count}
end
