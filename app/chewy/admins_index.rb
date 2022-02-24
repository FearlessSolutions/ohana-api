class AdminsIndex < Chewy::Index
  define_type Admin do
    field :name, type: 'text'
    field :email, type: 'keyword'
    field :super_admin, type: 'boolean'
    field :domain, type: 'keyword'
  end
end
