class PagesController < ApplicationController
  # Página del grabador. Se renderiza sin layout (es un documento HTML completo).
  def recorder
    render layout: false
  end
end
