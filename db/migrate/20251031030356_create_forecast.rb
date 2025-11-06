class CreateForecast < ActiveRecord::Migration[8.0]
  def change
    create_table :forecasts do |t|
      t.references :location, null: false, foreign_key: true
      t.jsonb :data
      
      t.timestamps
    end
  end
end
