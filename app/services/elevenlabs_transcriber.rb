require "faraday"
require "faraday/multipart"

# Transcribe un Active Storage attachment con ElevenLabs Scribe (speech-to-text).
# Devuelve [texto, palabras] donde palabras es [{ "w" =>, "s" =>, "e" => }, ...].
class ElevenlabsTranscriber
  ENDPOINT = "https://api.elevenlabs.io/v1/speech-to-text".freeze
  MODEL    = "scribe_v1".freeze
  LANGUAGE = "spa".freeze # ISO-639-3 español

  class NotConfigured < StandardError; end
  class ApiError < StandardError; end

  def initialize(api_key: ENV["ELEVENLABS_API_KEY"])
    @api_key = api_key.to_s
  end

  def configured?
    @api_key.present?
  end

  def call(attachment)
    raise NotConfigured, "ELEVENLABS_API_KEY missing" unless configured?

    attachment.blob.open do |tempfile|
      part = Faraday::Multipart::FilePart.new(
        tempfile.path,
        attachment.content_type.presence || "application/octet-stream",
        attachment.filename.to_s
      )

      response = connection.post(ENDPOINT) do |req|
        req.headers["xi-api-key"] = @api_key
        req.body = {
          "file"                   => part,
          "model_id"               => MODEL,
          "language_code"          => LANGUAGE,
          "diarize"                => "false",
          "tag_audio_events"       => "false",
          "timestamps_granularity" => "word"
        }
      end

      unless response.success?
        raise ApiError, "ElevenLabs HTTP #{response.status}: #{response.body.to_s[0, 300]}"
      end

      data  = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body.to_s)
      words = Array(data["words"])
                .select { |w| w["type"].nil? || w["type"] == "word" }
                .map { |w| { "w" => w["text"], "s" => w["start"], "e" => w["end"] } }

      [data["text"].to_s.strip, words]
    end
  end

  private

  def connection
    @connection ||= Faraday.new do |f|
      f.request :multipart
      f.response :json, content_type: /\bjson$/
      f.options.timeout      = 300
      f.options.open_timeout = 30
      f.adapter Faraday.default_adapter
    end
  end
end
