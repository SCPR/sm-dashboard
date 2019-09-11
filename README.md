---
   sm-dashboard
---

# Streammachine Analytics

## Listeners by Show
/schedule

### Listeners by Device
/

## Listeners by stream
/api/listens



# Deployment

## How to run locally
Make sure you have a valid `config/secrets.yml`. If you're unsure of what it should look like, take a look at `config/secrets.yml.template`

`bundle install`

`bundle exec rails s`

## How to run in production

`/startup.sh` starts passenger, which runs the app.
