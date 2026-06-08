class TranscribeClipJob < ApplicationJob
  queue_as :default

  # Si el clip fue borrado, no tiene sentido reintentar.
  discard_on ActiveJob::DeserializationError

  # Errores transitorios de red/API: reintenta con backoff; si se agotan, marca failed.
  retry_on Faraday::Error, ElevenlabsTranscriber::ApiError,
           wait: :polynomially_longer, attempts: 4 do |job, error|
    clip = job.arguments.first
    clip.update!(transcript_status: "failed") if clip.is_a?(Clip)
    Rails.logger.error("[TranscribeClipJob] giving up on clip #{clip&.id}: #{error.message}")
  end

  def perform(clip)
    return unless clip.file.attached?
    return if clip.transcript_done?

    transcriber = ElevenlabsTranscriber.new
    return unless transcriber.configured? # sin API key (p.ej. en dev): queda pending

    clip.update!(transcript_status: "processing")
    text, words = transcriber.call(clip.file)
    clip.update!(
      transcript: text,
      transcript_words: words,
      transcript_status: "done",
      transcribed_at: Time.current
    )
  end
end
