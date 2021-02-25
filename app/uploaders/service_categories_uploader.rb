class ServiceCategoriesUploader
  class ServiceCategoriesUploadError < StandardError
  end

  def initialize(file_path)
    @file_path = file_path
  end

  def process
    csv = SmarterCSV.process(@file_path)

    errors = []
    csv.map do |attributes|

      # Find service and raise if it's not found
      service = Service.find_by(id: attributes[:id])
      unless service
        message = "Service with ID #{attributes[:id]}"
        errors << message
      end

      # If there is a new category set find and set the category, otherwise create it.
      new_parent_string = attributes[:new_category]
      if new_parent_string.present?
        service.categories = []
        category = Category.find_or_create_by(name: new_parent_string)
        service.categories << category

        # same deal for the subcategory
        subcategory_string = attributes[:new_subcategory]
        if subcategory_string.present?
          subcategory = category.children.find_or_create_by(name: subcategory_string)
          service.categories << subcategory
        end
      end

      # Clearing the categories clears the categories no matter what
      if attributes[:clear_categories] == 'clear'
        service.categories = []
      end

      # if service doesn't save throw an error
      if !service.persisted?
        raise ServiceUploadError, I18n.t(
          'admin.services.upload.validation_errors',
          errors: service.errors.full_messages.join(", "),
          service_id:service.id
        )
      end

      service
    end
  end

  private

  def find_or_create_tags(service, tags)
    return unless tags.present?

    tags.split(/\s*,\s*/).map do |tag|
      Tag.find_or_create_by(name: tag)
    end.map do |tag|
      TagResource.find_or_create_by(
        resource_id: service.id,
        tag_id: tag.id,
        resource_type: 'Service'
      )
    end
  end

  def find_or_create_contact(service, name, title, email)
    contact = Contact.find_or_initialize_by(name: name)
      contact.name = name
      contact.title = title
      contact.email = email
      contact.save
    if service.contacts.find_by(id: contact.id).nil?
      service.contacts << contact
    end
  end
end
