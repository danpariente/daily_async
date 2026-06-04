class DailiesController < ApplicationController
  def index
    @date = parse_date(params[:date])
    @dailies = Daily.where(on_date: @date)
                    .includes(clips: { file_attachment: :blob })
                    .order(:dev_name)
  end

  private

  def parse_date(str)
    Date.iso8601(str.to_s)
  rescue ArgumentError
    Date.current
  end
end
