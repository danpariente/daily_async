class CreateClips < ActiveRecord::Migration[8.0]
  def change
    create_table :clips do |t|
      t.references :daily, null: false, foreign_key: true
      t.string  :kind                       # video | audio | pantalla
      t.integer :duration_seconds, default: 0
      t.json    :marks, default: []         # [{q,label,t}]
      t.timestamps
    end
  end
end
