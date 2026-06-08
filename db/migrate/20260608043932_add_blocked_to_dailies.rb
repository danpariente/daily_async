class AddBlockedToDailies < ActiveRecord::Migration[8.1]
  def change
    add_column :dailies, :blocked, :boolean, null: false, default: false
    add_column :dailies, :blocker_note, :string
    add_column :dailies, :analysis_status, :string, null: false, default: "pending"
    add_column :dailies, :analyzed_at, :datetime
  end
end
