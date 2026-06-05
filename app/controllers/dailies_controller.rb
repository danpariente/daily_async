class DailiesController < ApplicationController
  # Protege el tablero del lead con HTTP Basic auth. El grabador (/) sigue público.
  before_action :authenticate_lead

  def index
    @date = parse_date(params[:date])
    @dailies = Daily.where(on_date: @date)
                    .includes(clips: { file_attachment: :blob })
                    .order(:dev_name)
  end

  private

  # Pide usuario/contraseña vía ENV (DASHBOARD_USER / DASHBOARD_PASSWORD).
  # Si no están configurados (p.ej. en desarrollo), el tablero queda abierto.
  def authenticate_lead
    user = ENV["DASHBOARD_USER"]
    pass = ENV["DASHBOARD_PASSWORD"]
    return if user.blank? || pass.blank?

    authenticate_or_request_with_http_basic("Async Daily") do |u, p|
      ActiveSupport::SecurityUtils.secure_compare(u.to_s, user) &
        ActiveSupport::SecurityUtils.secure_compare(p.to_s, pass)
    end
  end

  def parse_date(str)
    Date.iso8601(str.to_s)
  rescue ArgumentError
    Date.current
  end
end
