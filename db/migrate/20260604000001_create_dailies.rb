class CreateDailies < ActiveRecord::Migration[8.0]
  def change
    create_table :dailies do |t|
      t.string :dev_name, null: false
      t.date   :on_date,  null: false
      t.timestamps
    end
    add_index :dailies, [:dev_name, :on_date]
  end
end
