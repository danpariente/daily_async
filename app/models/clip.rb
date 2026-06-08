class Clip < ApplicationRecord
  belongs_to :daily
  has_one_attached :file

  # Estado de la transcripción (ElevenLabs Scribe), poblado por TranscribeClipJob.
  enum :transcript_status,
       { pending: "pending", processing: "processing", done: "done", failed: "failed" },
       prefix: :transcript
end
