class Clip < ApplicationRecord
  belongs_to :daily
  has_one_attached :file
end
