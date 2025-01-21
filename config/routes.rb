require "api_constraints"
require "subdomain_constraints"

Rails.application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.
  # See how all your routes lay out with 'rake routes'.
  # Read more about routing: http://guides.rubyonrails.org/routing.html
  case Rails.configuration.upload_server
  when :s3_multipart
    mount Shrine.uppy_s3_multipart(:cache) => "/s3/multipart"
  when :app
    mount Shrine.upload_endpoint(:cache) => "/uploads"
  end

  devise_for :users, controllers: { registrations: "user/registrations" }
  devise_for(
    :admins, path: "/admin", controllers: { registrations: "admin/registrations" },
  )

  namespace :admin, path: "admin" do
    root to: "dashboard#index", as: :dashboard
    get "/csv_downloads", to: "dashboard#csv_downloads", as: "csv_downloads"

    resources :locations, except: :show do
      resources :services, except: %i[show index] do
        resources :contacts, except: %i[show index], controller: "service_contacts"
      end
      resources :contacts, except: %i[show index]
    end

    resources :organizations, except: :show do
      resources :contacts, except: %i[show index], controller: "organization_contacts"
    end
    resources :programs, except: :show
    resources :services, only: :index

    resources :flags
    resources :flag_categories

    resources :tags
    resources :recommended_tags

    namespace :csv, defaults: { format: "csv" } do
      get "addresses"
      get "categories"
      get "contacts"
      get "covid_19_locations"
      get "food_and_covid_services"
      get "holiday_schedules"
      get "locations"
      get "organizations"
      get "phones"
      get "programs"
      get "regular_schedules"
      get "services"
      get "service_categories"
      post "upload_services"
      post "upload_service_categories"
    end

    get 'capacity', to: 'locations#capacity'
    get 'locations/:location_id/services/:id', to: 'services#edit'
    get 'locations/:location_id/services/:service_id/contacts/:id', to: 'service_contacts#edit'
    patch 'locations/:location_id/services/:id/update_capacity', to: 'services#update_capacity', as: "service_update_capacity"
    get 'locations/:location_id/contacts/:id', to: 'contacts#edit'
    get 'locations/:id', to: 'locations#edit'
    get 'organizations/:id', to: 'organizations#edit'
    get 'organizations/:organization_id/contacts/:id', to: 'organization_contacts#edit'
    get 'programs/:id', to: 'programs#edit'

    namespace :management do
      resources :admins, only: %i[index edit update]
      resources :super_admins, only: %i[index edit update]
    end
    put '/drop_admin', to: 'management#drop_admin', as: 'drop_from_location'

    get 'analytics', to: 'analytics#index'
    post 'analytics', to: 'analytics#update'
    post 'services', to: 'services#archive'
    post 'locations/archive', to: 'locations#archive'
  end

  namespace :api, path: "/api", defaults: { format: "json" } do
    scope module: :v1, constraints: ApiConstraints.new(version: 1) do
      get "/" => "root#index"
      get ".well-known/status" => "status#check_status"

      post "flag" => "flags#create"
      get "/s3/multipart" => "#<Shrine::UploadEndpoint(:cache)>"
      get "/upload" => "#<Shrine::UploadEndpoint(:cache)>"

      resources :organizations do
        resources :locations, only: :create
      end
      get "organizations/:organization_id/locations",
          to: "organizations#locations", as: :org_locations

      get "lookahead", to: "search#lookahead", as: :lookahead

      resources :locations do
        resources :address, except: %i[index show]
        resources :contacts, except: [:show] do
          resources :phones,
                    except: %i[show index],
                    path: "/phones", controller: "contact_phones"
        end
        resources :phones, except: [:show], path: "/phones", controller: "location_phones"
        resources :services
      end

      resources :search, only: :index
      get "search_needs", to: "search#search_needs"

      resources :categories, only: :index

      put "services/:service_id/categories",
          to: "services#update_categories", as: :service_categories
      get "categories/:taxonomy_id/children", to: "categories#children", as: :category_children
      get "locations/:location_id/nearby", to: "search#nearby", as: :location_nearby

      resources :recommended_tags, only: :index
      resources :languages, only: :index

      match "*unmatched_route" => "errors#raise_not_found!",
            via: %i[get delete patch post put]

      # CORS support
      match "*unmatched_route" => "cors#render_204", via: [:options]
    end
  end

  root to: "home#index"

  resources :locations, only: [:index] do
    collection do
      post 'get_subcategories_by_category', to: 'locations#get_subcategories_by_category'
      post 'set_search_rating', to: 'locations#set_search_rating'
    end
  end

  get 'locations/*id/' => 'locations#show', as: 'location'
  get '/about' => 'about#index'
  post '/feedback' => 'feedback#create'
  get '/feedback' => 'feedback#new'
  get '.well-known/status' => 'status#check_status'

  post '/favorite.json' => 'favorites#create'
  delete '/favorite.json' => 'favorites#destroy'
  get 'favorites' => 'favorites#index'

  resource :flag, only: [:new, :create]
end
