class Daily < ApplicationRecord
  has_many :clips, -> { order(:id) }, dependent: :destroy
  validates :dev_name, presence: true
  validates :on_date,  presence: true

  def self.upsert_for(dev_name, on_date)
    find_or_create_by!(dev_name: dev_name.to_s.strip.presence || "dev", on_date: on_date)
  end
end
