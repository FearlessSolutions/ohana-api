class CreateFaxes < ActiveRecord::Migration[5.1]
  def change
    create_table :faxes do |t|
      t.belongs_to :location
      t.text :number
      t.text :department

      t.timestamps
    end
    # add_index :faxes, :location_id
  end
end
