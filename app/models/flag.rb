class Flag < ApplicationRecord
  extend ActiveModel::Naming
  include ActiveModel::AttributeMethods

  store_accessor :report, :report_attributes

  belongs_to :resource, polymorphic: true

  validates :email,
            format: { with: EMAIL_REGEX, message: 'wrong format' },
            if: ->(flag) { flag.email.present? }

  # validates_length_of :description, maximum: 250, allow_blank: false

  validate :check_report_attributes

  after_initialize :set_default_report_attributes

  def resource_path
    paths = Rails.application.routes.url_helpers

    case resource_type
    when 'Location'
      paths.edit_admin_location_path(resource)
    when 'Organization'
      paths.edit_admin_organization_path(resource)
    when 'Service'
      paths.edit_admin_service_path(resource)
    end
  end

  #pulling in the below from UI
  def self.report_attributes_schema
    [
      {
        name: :hours_location_contact_info_incorrect,
        label: "The hours, location, or contact information is incorrect"
      },
      {
        name: :the_info_listed_is_incorrect,
        label: "Information listed on this resource page is incorrect"
      },
      {
        name: :other,
        label: "Other",
        details_required: true
      },
      {
        name: :employee_of_the_org,
        label: "I am an employee of the organization",
        details_required: true
      }
    ]
  end

  def self.details_required?(attr_name)
    get_schema_attribute_by_name(attr_name)[:details_required] != false
  end

  def self.get_schema_attribute_by_name(name)
    attribute = report_attributes_schema.find do |ar|
      ar[:name] == name
    end
    attribute
  end

  def self.report_attributes_in_order
    Flag.report_attributes_schema.collect(&:values).transpose[0]
  end

  def self.get_report_attribute_label_for(attr)
    attribute = report_attributes_schema.find do |ar|
      ar[:name].to_s.include?(attr)
    end

    attribute ? attribute[:label] : attr[0]
  end

  def self.serialize_report_attributes(report_attributes)
    return {} if report_attributes.empty?
    serialized_attributes = {}
    Flag.report_attributes_schema.each_with_index do |attribute, index|
      attr_name = attribute[:name]
      attr_label = attribute[:label]
      selection_input = report_attributes.find do |input_name, input_value|
        input_name.include?(attr_name.to_s + '_selected')
      end

      selected = selection_input[1]
      selected = "1" if selection_input[1] == "true"

      value_input = report_attributes.find do |input_name, input_value|
        input_name == attr_name.to_s
      end
      if selected == "1" && Flag.details_required?(attr_name)
        value = value_input[1]
      else
        value = "No details required"
      end

      serialized_attributes[index] = {
        prompt: attr_label,
        selected: selected,
        value: value
      }
    end
    serialized_attributes
  end

  update_index('locations') { Location.find(self.resource_id) }

  # from api again
  private

  def set_default_report_attributes
    self.report_attributes = {} if self.report_attributes.nil?
  end

  def check_report_attributes
    if report_attributes.nil? || report_attributes.all? {|k, v| v["value"].blank? || v["value"] == "0" }
      errors.add(:report_attributes, "can't be blank")
    end
  end

end



