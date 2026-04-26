require 'committee/rails/test/methods'

RSpec.configure do |config|
  config.add_setting :committee_options

  config.committee_options = {
    schema_path: Rails.root.join('swagger/v1/swagger.yaml').to_s,
    parse_response_by_content_type: true,
    query_hash_key: 'rack.request.query_hash',
    prefix: nil,
    strict_reference_validation: true
  }

  config.include Committee::Rails::Test::Methods, type: :request
end
