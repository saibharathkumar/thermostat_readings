class ReadingsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :set_thermostat, except: :index
  before_action :parameters_validator, only: :create

  # return all thermostat records
  def index
    @thermostat = Thermostat.all
  end

  def create
    begin
      $redis.set(@tracking_number, permit_params.merge!(thermostat_id: @thermostat.id, tracking_number: @tracking_number)) #caching in redis
      ReadingWorker.perform_async(@tracking_number, @thermostat.id, @temperature, @humidity, @battery_charge)
      render json: {tracking_number: @tracking_number}
    rescue Redis::CannotConnectError => e
      render json: {error: "#{e.message}"}
    end
  end

  # return reading data for a particular thermostat
  def show
    begin
      reading = Reading.find_by(tracking_number: params[:id], thermostat_id: @thermostat.id)
      render json: { message: "Data not found for given Tracking Number" } and return if !reading
      render json: reading
    rescue Redis::CannotConnectError => e
      render json: {error: "#{e.message}"}
    end
  end

  # return array of hash with avg, min and max by temerature, humidity and battery_charge for a particular thermostat
  def stats
    db_data = data_store
    redis_data = redis_store

    @output = []
    if redis_data.empty?
      @output = db_data
    elsif db_data.empty?
      @output = redis_data
    else
      db_data.each_with_index do |val,i|
        val.each do |k,value|
          avg_val = (value["avg"].to_f + redis_data[i][k]["avg"].to_f) / 2
          min_val = [value["min"].to_f, redis_data[i][k]["min"].to_f].min
          max_val = [value["max"].to_f, redis_data[i][k]["max"].to_f].max
          @output << {k => {avg: avg_val, min: min_val, max: max_val} }
        end
      end
    end
    respond_to do |format|

      format.html # show.html.erb
      format.json { render json: { thermostat_data: @output } }

    end
    # render json: { thermostat_data: output }
  end

  private
  # set thermostat based on household token
  def set_thermostat
    token = params[:household_token]
    render json: { message: 'Please provide household token.' }, status: 401 and return if !token
    @thermostat = Thermostat.find_by(household_token: token)
    render json: { message: 'Household token is invalid !' }, status: 401 and return if !@thermostat
  end

  def parameters_validator
    if %w(temperature humidity battery_charge).all? {|key| params[key].present?}
      @temperature = params[:temperature]
      @humidity = params[:humidity]
      @battery_charge = params[:battery_charge]
      @tracking_number = Reading.next_number
      reading = Reading.new(permit_params.merge!(thermostat_id: @thermostat.id, tracking_number: @tracking_number))
      render json: { errors: reading.errors } and return if reading.invalid?
    else
      render json: { message: 'Please check paramaters and values should be present.' }, status: 400
    end
  end

  def permit_params
    params.permit(:temperature, :humidity, :battery_charge)
  end

  # return avg,min,max for a thermostat from the db
  def data_store
    data = []
    aggregation = @thermostat.readings.pluck('Avg(temperature)', 'Min(temperature)', 'Max(temperature)', 'Avg(humidity)', 'Min(humidity)', 'Max(humidity)', 'Avg(battery_charge)', 'Min(battery_charge)', 'Max(battery_charge)').first
    unless aggregation.empty?
      data << { temperature: {"avg" => aggregation[0].round(2), "min" => aggregation[1], "max" => aggregation[2]}}
      data << { humidity: {"avg" => aggregation[3].round(2), "min" => aggregation[4], "max" => aggregation[5]}}
      data << { battery_charge: {"avg" => aggregation[6].round(2), "min" => aggregation[7], "max" => aggregation[8]}}
    end
    return data
  end

  # return avg,min,max for a thermostat from the redis
  def redis_store
    redis_data = []
    cache_result = []
    begin
      redis_keys = $redis.keys
      unless redis_keys.empty?
        redis_keys.each do |k|
          reading = eval($redis.get(k))
          next if !reading["household_token"].eql?(params[:household_token])
          redis_data << { temperature: reading["temperature"], humidity: reading["humidity"],  battery_charge: reading["battery_charge"] }
        end
      end

      unless redis_data.blank?
        thermostat_attr = ["temperature", "humidity", "battery_charge"]
        avg_data = avg_data(thermostat_attr, redis_data)
        min_data = min_data(thermostat_attr, redis_data)
        max_data = max_data(thermostat_attr, redis_data)
        cache_result << { temperature: {"avg" => avg_data[0].round(2), "min" => min_data[0], "max" => max_data[0]}}
        cache_result << { humidity: {"avg" => avg_data[1].round(2), "min" => min_data[1], "max" => max_data[1]}}
        cache_result << { battery_charge: {"avg" => avg_data[2].round(2), "min" => min_data[2], "max" => max_data[2]}}
      end
      return cache_result
    rescue Redis::CannotConnectError => e
      p "redis server not up"
      return cache_result
    end
  end

  # return avg by temerature, humidity and battery_charge
  def avg_data(thermostat_attr, redis_data)
    thermostat_attr.map do |type|
      redis_data.map { |x| x[type].to_f }.sum / redis_data.size
    end
  end

  # return min by temerature, humidity and battery_charge
  def min_data(thermostat_attr, redis_data)
    thermostat_attr.map do |type|
      redis_data.min_by { |h| h[type].to_i }[type]
    end
  end

  # return max by temerature, humidity and battery_charge
  def max_data(thermostat_attr, redis_data)
    thermostat_attr.map do |type|
      redis_data.max_by { |h| h[type].to_i }[type]
    end
  end
end
