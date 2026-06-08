require "faraday"
require "json"

# Analiza la transcripción de un daily (en español) en UNA sola llamada a OpenAI:
#   1. Separa lo dicho por pregunta (ayer / hoy / bloqueos) en verbatim limpio.
#   2. Deduce si el dev está bloqueado + una nota de una línea.
# Devuelve { "segments" => { "ayer"=>, "hoy"=>, "bloqueos"=> }, "blocked" => bool, "note" => String }.
class OpenaiDailyAnalyzer
  ENDPOINT      = "https://api.openai.com/v1/chat/completions".freeze
  DEFAULT_MODEL = "gpt-4o-mini".freeze

  SYSTEM_PROMPT = <<~PROMPT.freeze
    Analizas el daily standup (en español) de un desarrollador a partir de la transcripción de su grabación.

    Haz DOS cosas:

    1) SEGMENTAR por las tres preguntas del daily: "ayer" (qué hizo ayer), "hoy" (qué hará hoy)
       y "bloqueos" (impedimentos). Para cada una devuelve SUS PROPIAS PALABRAS en "verbatim limpio":
       elimina muletillas, titubeos, repeticiones y falsos comienzos (eh, este, o sea, "no, perdón"),
       pero NO parafrasees, NO resumas y NO inventes. Conserva el significado y el detalle, corrige solo
       puntuación obvia. Si no dijo nada de una pregunta, usa cadena vacía.

    2) DECIDIR si está BLOQUEADO: si expresa un impedimento que le impide avanzar (espera a otra persona,
       un bug que no logra resolver, falta de acceso/credenciales/información, una dependencia externa, o
       pide ayuda o una decisión). NO está bloqueado si solo describe trabajo normal, dice que no tiene
       bloqueos, o el contenido no trata sobre trabajo. Ante la duda, blocked=false. La nota resume el
       bloqueo en UNA frase corta en español (cadena vacía si no está bloqueado).

    Responde ÚNICAMENTE en JSON con esta forma exacta:
    {"segments": {"ayer": "...", "hoy": "...", "bloqueos": "..."}, "blocked": true|false, "note": "..."}
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
    return blank_result if transcript.blank?

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
    segments = parsed["segments"].is_a?(Hash) ? parsed["segments"] : {}

    {
      "segments" => {
        "ayer"     => segments["ayer"].to_s.strip,
        "hoy"      => segments["hoy"].to_s.strip,
        "bloqueos" => segments["bloqueos"].to_s.strip
      },
      "blocked" => parsed["blocked"] == true,
      "note"    => parsed["note"].to_s.strip
    }
  end

  private

  def blank_result
    { "segments" => { "ayer" => "", "hoy" => "", "bloqueos" => "" }, "blocked" => false, "note" => "" }
  end

  def connection
    @connection ||= Faraday.new do |f|
      f.response :json, content_type: /\bjson$/
      f.options.timeout      = 60
      f.options.open_timeout = 30
      f.adapter Faraday.default_adapter
    end
  end
end
