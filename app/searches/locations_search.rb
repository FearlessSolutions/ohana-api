class LocationsSearch
  include ActiveData::Model

  PAGE = 1
  PER_PAGE = 30

  attribute :zipcode, type: String
  attribute :keywords, type: String
  attribute :org_name, type: String
  attribute :category_ids, type: Array
  attribute :tags, type: String
  attribute :archived_at, type: Date
  attribute :archived, type: Boolean
  attribute :accessibility, type: Array
  attribute :lat, type: Float
  attribute :long, type: Float
  attribute :distance, type: Integer
  attribute :languages, type: Array

  attribute :page, type: String
  attribute :per_page, type: String

  attribute :matched_category, type: Object

  def index
    LocationsIndex
  end

  def search
    query = LocationsIndex.query(build_query)
    query = apply_filters(query)
    query = apply_sorting(query)
    search_results = query.page(fetch_page).per(fetch_per_page)
    search_results
  end

  def exact_match_found?
    keyword_to_use = keywords || attributes[:keyword]

    return true if matched_category.present?
    return false if keyword_to_use.blank?

    combined_query = index.query(bool: {
      should: [
        # Exact matches
        { term: { "organization_name_exact": { value: keyword_to_use.downcase } } },
        { term: { "name_exact": { value: keyword_to_use.downcase } } },
        { term: { "categories_exact": { value: keyword_to_use.downcase } } },
        { match_phrase: { "organization_name": { query: keyword_to_use, slop: 0 } } },
        { match_phrase: { "name": { query: keyword_to_use, slop: 0 } } },
        { match_phrase: { "categories": { query: keyword_to_use, slop: 0 } } },
        # Partial matches
        { match_phrase: { "organization_name": { query: keyword_to_use } } },
        { match_phrase: { "name": { query: keyword_to_use } } },
        { match_phrase: { "categories": { query: keyword_to_use } } },
        { match_phrase: { "organization_tags": { query: keyword_to_use } } },
        { match_phrase: { "description": { query: keyword_to_use } } },
        { match_phrase: { "service_descriptions": { query: keyword_to_use } } }
      ],
      minimum_should_match: 1
    })

    results = combined_query.count
    results > 0
  end

  private

  def search_results
    # Order matters
    [
      organization_filter,
      archive_filter,
      keyword_filter,
      tags_query,
      zipcode_filter,
      category_filter,
      language_filter,
      accessibility_filter,
      distance_filter,
      distance_sort,
      order,
    ].compact.reduce(:merge)
  end

  def distance_filter(query = index)
    return query unless distance? && lat? && long?

    d = distance.to_s + "mi"
    query.filter(geo_distance: {
      distance: d,
      coordinates: {
        lat: lat,
        lon: long
      }
    })
  end

  def distance_sort
    return unless lat? && long?

    index.order(_geo_distance: {
      coordinates: {
        lat: lat,
        lon: long
      }
    })
  end

  def order
    index.order(
      "_score": { "order": "desc" },
      updated_at: { order: "desc" }
    )
  end

  def tags_query
    return unless tags?

    index.query(multi_match: {
      query: tags,
      fields: %w[tags],
      analyzer: 'standard',
      fuzziness: 'AUTO'
    })
  end

  def category_filter(query = index)
    return query unless category_ids?

    query.filter(
      terms: {
        category_ids: category_ids
      }
    )
  end

  def language_filter(query = index)
    return query unless languages?

    query.filter(
      terms: {
        languages: languages
      }
    )
  end

  def accessibility_filter(query = index)
    return query unless accessibility.present?

    query.filter(
      terms: {
        accessibility: accessibility.map(&:to_s)
      }
    )
  end

  def archive_filter(query = index)
    query.filter(
      term: {
        archived: {
          value: false
        }
      }
    )
  end

  def zipcode_filter(query = index)
    return query unless zipcode?

    query.filter(match: {
      zipcode: zipcode
    })
  end

  def keyword_filter(query = index)
    return query unless keywords?

    query.query(bool: {
      should: [
        { term: { "service_names_exact": { value: keywords.downcase, boost: 10 } } },
        { term: { "service_description_exact": { value: keywords.downcase, boost: 8 } } },
        { term: { "service_tags_exact": { value: keywords.downcase, boost: 5 } } },
        { term: { "name": { value: keywords.downcase, boost: 1 } } }
      ],
      must: [{
        multi_match: {
          query: keywords,
          fields: %w[service_names^10 service_descriptions^8 service_tags^7 organization_name^4 name^3 categories^2 organization_tags^1 tags description keywords],
          fuzziness: 'AUTO'
        }
      }]
    })
  end

  def organization_filter(query = index)
    return query unless org_name?

    terms = org_name.downcase.split.map(&:strip)
    query.query(
      bool: {
        must: terms.map { |term|
          {
            match_phrase: {
              organization_name: {
                query: term,
                slop: 0
              }
            }
          }
        }
      }
    )
  end

  def fetch_page
    page.presence || PAGE
  end

  def fetch_per_page
    per_page.presence || PER_PAGE
  end

  def build_query
    base_query = if matched_category.is_a?(Category)
      {
        bool: {
          should: [
            { term: { category_ids: matched_category.id } },
            { term: { "categories_exact": matched_category.name.downcase } }
          ]
        }
      }
    elsif keywords.present?
      {

        bool: {
          should: [
            # Exact phrase matches
            { match_phrase: { "service_name": { query: keywords, boost: 10 } } },
            { match_phrase: { "service_descriptions": { query: keywords, boost: 8 } } },
            { match_phrase: { "service_tags": { query: keywords, boost: 5 } } },
            { match_phrase: { "name": { query: keywords, boost: 1 } } },

            # All words must match
            { match: { "service_name": { query: keywords, boost: 10, operator: "and" } } },
            { match: { "service_descriptions": { query: keywords, boost: 8, operator: "and" } } },
            { match: { "service_tags": { query: keywords, boost: 5, operator: "and" } } },
            { match: { "name": { query: keywords, boost: 1, operator: "and" } } },

            # Partial and fuzzy matches
            { multi_match: {
                query: keywords,
                fields: %w[
                  service_names^10
                  service_descriptions^8
                  service_tags^7
                  organization_name^4
                  name^3
                  categories^2
                  organization_tags^1
                  tags
                  description
                  keywords],
                type: "best_fields",
                fuzziness: 'AUTO',
                prefix_length: 2
              }
            }
          ],
          minimum_should_match: 1
        }
      }
    else
      { match_all: {} }
    end

    {
      function_score: {
        query: base_query,
        functions: [
          {
            filter: { exists: { field: "featured_at" } },
            weight: 1.2
          }
        ],
        boost_mode: "multiply"
      }
    }
  end

  def apply_filters(query)
    filters = [
      [:archive_filter, true],
      [:organization_filter, org_name?],
      [:tags_query, tags?],
      [:category_filter, category_ids?],
      [:accessibility_filter, accessibility.present?],
      [:zipcode_filter, zipcode?],
      [:distance_filter, distance? && lat? && long?],
      [:language_filter, languages?],
      [:keyword_filter, keywords?]
    ]

    filters.each do |filter_method, condition|
      query = send(filter_method, query) if condition
    end

    query
  end

  def apply_sorting(query)
    query.order(
      "_score": { "order": "desc" },
      updated_at: { order: "desc" }
    )
  end
end
