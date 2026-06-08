class AnalyzeDailyJob < ApplicationJob
  queue_as :default

  discard_on ActiveJob::DeserializationError

  retry_on Faraday::Error, OpenaiBlockerAnalyzer::ApiError,
           wait: :polynomially_longer, attempts: 4 do |job, error|
    daily = job.arguments.first
    daily.update!(analysis_status: "failed") if daily.is_a?(Daily)
    Rails.logger.error("[AnalyzeDailyJob] giving up on daily #{daily&.id}: #{error.message}")
  end

  def perform(daily)
    analyzer = OpenaiBlockerAnalyzer.new
    return unless analyzer.configured? # sin API key (p.ej. en dev): queda pending

    daily.update!(analysis_status: "processing")
    result = analyzer.call(daily.combined_transcript)
    daily.update!(
      blocked: result["blocked"],
      blocker_note: result["note"],
      analysis_status: "done",
      analyzed_at: Time.current
    )
  end
end
