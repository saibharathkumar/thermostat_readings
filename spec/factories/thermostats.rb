FactoryBot.define do
  factory :thermostat do
    household_token { SecureRandom.uuid }
    location { "Location1" }
  end
end
