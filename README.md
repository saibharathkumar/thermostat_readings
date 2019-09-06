# THERMOSTAT READINGS

Things you may want to cover:

* System dependencies

### -- Ruby version
> Ruby 2.5.1

### -- Rails Version
> Rails 5.1.4

### -- Database
> Postgresql

### -- Redis
> Redis 4.0

## Project Setup
PostgreSQL and Redis should be running.

### Enter into the project
`$ cd thermostat_readings`
###

### Install libraries
`$ bundle install`

## start redis-server and sidekiq
```
$ redis-server
$ bundle exec sidekiq
```

### Seed development data
> Note: Change the `database.yml` file according to your system postgresql database settings.
```
$ rails db:setup
$ rails db:seed
```

### Start the rails server
`$ rails s`

### Start the sidekiq service (in another tab)
`$ bundle exec sidekiq`

### -- Run the test suite
> rspec spec



# APIS


## 1. POST Reading:
> To create readings for a particular thermostat -

`curl -d "temperature=33.4&humidity=12.1&battery_charge=51" http://localhost:3000/readings?household_token=<HOUSEHOLD_TOKEN_FROM_DB>`

### Output
```
{"tracking_number":30}

  or

{"message":"Household token is invalid !"}
```

## 2. GET Reading:
> To get readings for a particular thermostat -

`http://localhost:3000/readings/1?household_token=<HOUSE-HOLD-TOKEN-FROM-DB>`

  OR

```
curl -X GET -d "household_token=<HOUSE-HOLD-TOKEN-FROM-DB>" http://localhost:3000/readings/:tracking_number

curl -X GET -d "household_token=<HOUSE-HOLD-TOKEN-FROM-DB>" http://localhost:3000/readings/12
```

### Output
```
{
  "id": 2,
  "thermostat_id": 1,
  "tracking_number": 1,
  "temperature": 74.05,
  "humidity": 98.07,
  "battery_charge": 71.01,
  "created_at": "2019-03-27T13:03:45.295Z",
  "updated_at": "2019-03-27T13:03:45.295Z"
}
  OR

{"message":"Data not found for given Number"}
```

## 3. GET Stats:
> To get statistics of thermostats -

`http://localhost:3000/stats.json?household_token=<HOUSE-HOLD-TOKEN-FROM-DB>`

OR 

`http://localhost:3000/stats?household_token=<HOUSE-HOLD-TOKEN-FROM-DB>`



# STATS method supports both html,json.
> please pass .json if you are expecting JSON response

`curl -X GET -d "household_token=<HOUSE-HOLD-TOKEN-FROM-DB>" http://localhost:3000/stats.json`

### Output
```
{
	"thermostat_data": [{
		"temperature": {
			"avg": 15.02,
			"min": 15.02,
			"max": 15.02
		}
	}, {
		"humidity": {
			"avg": 14.08,
			"min": 14.08,
			"max": 14.08
		}
	}, {
		"battery_charge": {
			"avg": 23.05,
			"min": 23.05,
			"max": 23.05
		}
	}]
}
```

