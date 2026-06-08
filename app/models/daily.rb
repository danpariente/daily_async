class Daily < ApplicationRecord
  has_many :clips, -> { order(:id) }, dependent: :destroy
  validates :dev_name, presence: true
  validates :on_date,  presence: true

  # Estado del análisis de bloqueo (LLM sobre las transcripciones), poblado por AnalyzeDailyJob.
  enum :analysis_status,
       { pending: "pending", processing: "processing", done: "done", failed: "failed" },
       prefix: :analysis

  def self.upsert_for(dev_name, on_date)
    find_or_create_by!(dev_name: dev_name.to_s.strip.presence || "dev", on_date: on_date)
  end

  # Todas las transcripciones del dev ese día, concatenadas (para el análisis).
  def combined_transcript
    clips.where(transcript_status: "done")
         .where.not(transcript: [nil, ""])
         .order(:id)
         .pluck(:transcript)
         .join("\n\n")
  end

  # Verbatim limpio por pregunta (poblado por AnalyzeDailyJob).
  def segment(key)
    (segments || {})[key.to_s].to_s
  end

  def segments?
    %w[ayer hoy bloqueos].any? { |k| segment(k).present? }
  end
end
