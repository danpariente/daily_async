require "faraday"
require "json"

# Analiza la transcripción de un daily y deduce si el dev está BLOQUEADO.
# Devuelve { "blocked" => bool, "note" => String } (note: resumen en una frase, en español).
class OpenaiBlockerAnalyzer
  ENDPOINT      = "https://api.openai.com/v1/chat/completions".freeze
  DEFAULT_MODEL = "gpt-4o-mini".freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Analizas el daily standup (en español) de un desarrollador a partir de la transcripción de su grabación.
    Decide si el desarrollador está BLOQUEADO: si expresa un impedimento que le impide avanzar
    (espera a otra persona, un bug que no logra resolver, falta de acceso/credenciales/información,
    una dependencia externa, o pide ayuda o una decisión). NO está bloqueado si solo describe su
    trabajo normal, dice explícitamente que no tiene bloqueos, o el contenido no trata sobre trabajo.
    Ante la duda, marca blocked=false.
    Responde ÚNICAMENTE en JSON con esta forma exacta:
    {"blocked": true|false, "note": "<resumen del bloqueo en UNA frase corta en español; cadena vacía si no está bloqueado>"}
  PROMPT

  class NotConfigured < StandardError; end
  class ApiError < StandardError; end

  def initialize(api_key: ENV["OPENAI_API_KEY"], model: ENV["OPENAI_MODEL"].presence || DEFAULT_MODEL)
    @api_key = api_key.to_s
    @model   = model
  end

  def configured?
    @api_key.present?
  end

  def call(transcript)
    raise NotConfigured, "OPENAI_API_KEY missing" unless configured?
    return { "blocked" => false, "note" => "" } if transcript.blank?

    response = connection.post(ENDPOINT) do |req|
      req.headers["Authorization"] = "Bearer #{@api_key}"
      req.headers["Content-Type"]  = "application/json"
      req.body = {
        model: @model,
        temperature: 0,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          { role: "user",   content: transcript }
        ]
      }.to_json
    end

    unless response.success?
      raise ApiError, "OpenAI HTTP #{response.status}: #{response.body.to_s[0, 300]}"
    end

    body    = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body.to_s)
    content = body.dig("choices", 0, "message", "content").to_s
    parsed  = JSON.parse(content) rescue {}

    { "blocked" => parsed["blocked"] == true, "note" => parsed["note"].to_s.strip }
  end

  private

  def connection
    @connection ||= Faraday.new do |f|
      f.response :json, content_type: /\bjson$/
      f.options.timeout      = 60
      f.options.open_timeout = 30
      f.adapter Faraday.default_adapter
    end
  end
end
