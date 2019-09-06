class Reading < ApplicationRecord
  # association
  belongs_to :thermostat

  # validations
  validates :tracking_number, presence: true, numericality: { only_integer: true }
  validates :temperature, presence: true, numericality: { only_float: true }
  validates :humidity, presence: true, numericality: { only_float: true }
  validates :battery_charge, presence: true, numericality: { only_float: true }

  after_create :clear_redis

  def self.next_number
    Reading.connection.select_value("Select nextval('readings_id_seq')")
  end

  def clear_redis
    begin
      $redis.del self.tracking_number
    rescue Redis::CannotConnectError => e
      #we can send alerts here
      p "Error connecting to Redis on 127.0.0.1:6379 (Errno::ECONNREFUSED)"
    end
  end
end
