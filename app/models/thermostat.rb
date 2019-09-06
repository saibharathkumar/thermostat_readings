class Thermostat < ApplicationRecord
  # associations
  has_many :readings, dependent: :destroy

  # validations
  validates :household_token, presence: true, uniqueness: true
  validates :location, presence: true
end
