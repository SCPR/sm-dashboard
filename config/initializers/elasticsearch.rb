ES_CONFIG = Hashie::Mash.new Rails.application.secrets.elasticsearch

ES_CLIENT = Elasticsearch::Client.new(
  hosts: [{
            host: ES_CONFIG.host,
            port: ES_CONFIG.port,
            user: ES_CONFIG.user,
            password: ES_CONFIG.password,
            scheme: ES_CONFIG.scheme
          }],
  retry_on_failure:   3,
  reload_connections: true,
)

ES_INDEX_TZ = ActiveSupport::TimeZone[ ES_CONFIG.index_timezone ]