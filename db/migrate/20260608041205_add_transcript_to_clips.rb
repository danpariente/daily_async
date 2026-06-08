class AddTranscriptToClips < ActiveRecord::Migration[8.1]
  def change
    add_column :clips, :transcript, :text
    add_column :clips, :transcript_status, :string, null: false, default: "pending"
    add_column :clips, :transcript_words, :json, default: []
    add_column :clips, :transcribed_at, :datetime
  end
end
