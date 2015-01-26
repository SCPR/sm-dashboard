ES_CONFIG = Hashie::Mash.new Rails.application.secrets.elasticsearch

ES_CLIENT = Elasticsearch::Client.new(
  hosts:              ES_CONFIG.host,
  retry_on_failure:   3,
  reload_connections: true,
)
