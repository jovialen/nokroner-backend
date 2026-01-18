# config/initializers/oas_rails.rb
OasRails.configure do |config|
  # Basic Information about the API
  config.info.title = "Nokroner API"
  config.info.version = "1.0.0"
  config.info.summary = "Nokroner: A personal finance app"
  config.info.description = <<~HEREDOC
    # Nokroner API

    This is the API documentation for the personal finance app Nokroner.

    ## Getting started

    In order to use the API demos in the documentation, you need to be
    authenticated. If you are not already logged in, you need to log in
    [here](/login).

    ## API authentication

    In order to use most of the API, you need to be authenticated. There are
    two methods that can be used to authenticate yourself to the API.

    The first option is to use a Bearer token. When logging in to the API, it
    will provide you with a Bearer token. Include this bearer token in the
    headers of your API calls. Alternatively, if cookies are supported by the
    querying program, a cookie will be saved with authentication information
    when you log in, and you will not require a Bearer token.
  HEREDOC
  config.info.contact.name = "Nicolai Frigaard"
  config.info.contact.email = "nicofri@pm.me"
  config.info.contact.url = "https://github.com/jovialen"

  # Servers Information. For more details follow: https://spec.openapis.org/oas/latest.html#server-object
  config.servers = [ { url: "http://localhost:3000", description: "Local" } ]

  # Tag Information. For more details follow: https://spec.openapis.org/oas/latest.html#tag-object
  config.tags = []

  # Optional Settings (Uncomment to use)

  # Extract default tags of operations from namespace or controller. Can be set to :namespace or :controller
  config.default_tags_from = :controller

  # Automatically detect request bodies for create/update methods
  # Default: true
  # config.autodiscover_request_body = false

  # Automatically detect responses from controller renders
  # Default: true
  # config.autodiscover_responses = false

  # API path configuration if your API is under a different namespace
  config.api_path = "/api/v1"

  # Apply your custom layout. Should be the name of your layout file
  # Example: "application" if file named application.html.erb
  # Default: false
  # config.layout = "application"

  # Override general rapidoc settings
  # config.rapidoc_configuration
  # default: {}

  # Add a logo to rapidoc
  # config.rapidoc_logo_url
  # default: nil

  # Override specific rapidoc theme settings
  # config.rapidoc_theme_configuration
  # default: {}

  # Excluding custom controllers or controllers#action
  # Example: ["projects", "users#new"]
  # config.ignored_actions = []

  # #######################
  # Authentication Settings
  # #######################

  # Whether to authenticate all routes by default
  # Default is true; set to false if you don't want all routes to include security schemas by default
  # config.authenticate_all_routes_by_default = true

  # Default security schema used for authentication
  # Choose a predefined security schema
  # [:api_key_cookie, :api_key_header, :api_key_query, :basic, :bearer, :bearer_jwt, :mutual_tls]
  config.security_schema = :api_key_cookie

  # Custom security schemas
  # You can uncomment and modify to use custom security schemas
  # Please follow the documentation: https://spec.openapis.org/oas/latest.html#security-scheme-object
  #
  # config.security_schemas = {
  #  bearer:{
  #   "type": "apiKey",
  #   "name": "api_key",
  #   "in": "header"
  #  }
  # }

  # ###########################
  # Default Responses (Errors)
  # ###########################

  # The default responses errors are set only if the action allow it.
  # Example, if you add forbidden then it will be added only if the endpoint requires authentication.
  # Example: not_found will be setted to the endpoint only if the operation is a show/update/destroy action.
  # config.set_default_responses = true
  # config.possible_default_responses = [:not_found, :unauthorized, :forbidden, :internal_server_error, :unprocessable_entity]
  # config.response_body_of_default = "Hash{ message: String }"
  # config.response_body_of_unprocessable_entity= "Hash{ errors: Array<String> }"
end
