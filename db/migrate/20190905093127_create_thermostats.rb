class CreateThermostats < ActiveRecord::Migration[5.1]
  def change
    create_table :thermostats do |t|
      t.string :household_token
      t.string :location
      t.timestamps
    end
  end
end
