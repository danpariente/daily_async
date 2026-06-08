class ClipsController < ApplicationController
  # Recibe un clip (multipart) desde el grabador y lo adjunta vía Active Storage (disco del VPS).
  def create
    daily = Daily.upsert_for(params[:dev], parse_date(params[:date]))
    clip  = daily.clips.create!(
      kind: params[:kind],
      duration_seconds: params[:duration].to_i,
      marks: parse_marks(params[:marks])
    )
    clip.file.attach(params[:file])
    TranscribeClipJob.perform_later(clip)
    render json: { ok: true, clip_id: clip.id, daily_id: daily.id }
  rescue => e
    render json: { ok: false, error: e.message }, status: :unprocessable_entity
  end

  private

  def parse_date(str)
    Date.iso8601(str.to_s)
  rescue ArgumentError
    Date.current
  end

  def parse_marks(str)
    JSON.parse(str.to_s)
  rescue JSON::ParserError
    []
  end
end
