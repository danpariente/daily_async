class AddSegmentsToDailies < ActiveRecord::Migration[8.1]
  def change
    # Transcripción verbatim limpia, separada por pregunta: { "ayer" =>, "hoy" =>, "bloqueos" => }
    add_column :dailies, :segments, :json, default: {}
  end
end
