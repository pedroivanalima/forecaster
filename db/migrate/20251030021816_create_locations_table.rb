class CreateLocationsTable < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.column :latitude, :decimal, precision: 4, scale: 2
      t.column :longitude, :decimal, precision: 5, scale: 2
      t.column :name, :string
      t.column :display_name, :string
      t.column :search, :string, array: true, default: []
      t.timestamps
    end

    add_index :locations, [:latitude, :longitude], unique: true, where: "latitude is not null and longitude is not null and latitude <> 99.99 and longitude <> 999.99"
    add_index :locations, :search, using: :gin
  end
end
