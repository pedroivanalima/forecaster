# Forecast

Forecaster is a program that gets a location address and fetches the forecast for the day and the next 7 days, including temperature and total rain fall on the day.

It is mean as a test/portfolio and most decisions make more sense thinking about scalability.

## Instaling

This project was built on ruby 3.4.7, rails 8.0.3 and postgresql 12.11

after creating the gemset for 3.4.7@forecaster, you should be able to
```
gem install bundler
bundle
```

For the database, it already has 2 locations to help testing, specially on development
```
rails db:create
rails db:migrate
rails db:setup
```

You also need to configure the .env file that will be covered at next section.  After .env file is configured, you will run it as

```
rails s
```

## .env && 3rd party

This system is utilizing 2 free api services available on web and you need to configure both at the .env.  They aren't meant to be used on large scale, but they are more than enough for showing purposes.

The service that translates an address to a location is https://geocode.maps.co/
There you can get an api key at https://geocode.maps.co/login/

The service that gets the forecast based on a location is https://open-meteo.com/ 
No need to register

your .env file should look like

```
geocode_url=https://geocode.maps.co
geocode_api_key=YOUR_API_KEY_HERE
open_meteo_url=https://api.open-meteo.com
```

## Main architecture and ideas

The main idea to scalability are:
- Caching responses when possible (30 minutes for forecast)
- External requests are always enqueued
- Assume that more than one server may be running (no session/memory control)
  
There are two models, one for locations and one fore forecasts, they have a 1 to 1 relationship, which means that we are not storing historical forecasts.

To abstract complexity from controllers and models, services were made.  Both services have 2 main methods: 
  - _call_ which receives the data request and it is going to either return the information, or enqueue a job to do it, returning a response that includes an http like status
  - _fetch_ which is called by the job and get the info from the 3rd party tools

## Location model

Location was decided to use decimal degrees because it is computer friendly and it goes from 0 to 90 on latitude and 0 to 180 on longitude, having many decimal digits.
Precision is important here, because it determines how accurate our system is and also the amount of data were're fetching and storing and it is a tradeoff of one for another.  Open-meteo utilizes models with a precision of 1 to 11km.  Based on https://gis.stackexchange.com/questions/8650/measuring-accuracy-of-latitude-and-longitude this would mean up to 2 decimal cases (for the more precise 1km).  1 less decimal case would still make sense for a more general approach and 10% of possibilities, but 2 sounded good enough.

To mark invalid locations, it was set 99.99 and 999.99 for latitude and longitude respectively, because they are invalid coordinates.

The location model also has a search array, which stores searches that matched it, avoiding calls to the same location fetching data from external sources.  It is a gin index from postgres.  Not used tsvector because it allows partial matches and we don't want it when dealing with location.

## Forecast model

It stores a ready to use version of the data fetch by the service.  It should remain in cache for 30 seconds, but it can be returned as a temporary result while we fetch new data, so the user isn't left empty handed when we have stale data.

## Closing

Thanks for reading everything, feel free to contact me to discuss anything.

Cheers!
