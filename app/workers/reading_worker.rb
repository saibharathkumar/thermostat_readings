class ReadingWorker
  include Sidekiq::Worker
  sidekiq_options retry: false

  def perform(tracking_number, thermostat_id, temperature, humidity, battery_charge)
    reading = Reading.new(thermostat_id: thermostat_id,
                          tracking_number: tracking_number,
                        temperature: temperature,
                        humidity: humidity,
                        battery_charge: battery_charge)
    reading.save!
  end
end
