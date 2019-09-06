class CreateReadings < ActiveRecord::Migration[5.1]
  def change
    create_table :readings do |t|
      t.references :thermostat, index1: true
      t.integer :tracking_number
      t.float :temperature
      t.float :humidity
      t.float :battery_charge
      t.timestamps
    end
  end
end
