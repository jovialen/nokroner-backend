Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]

  # get breadcrumbs from logs
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Add data like request headers and IP for users, if applicable;
  # see https://docs.sentry.io/platforms/ruby/data-management/data-collected/ for more info
  config.send_default_pii = true

  # enable tracing
  # we recommend adjusting this value in production
  config.traces_sample_rate = 1.0

  # enable profiling
  # this is relative to traces_sample_rate
  config.profiles_sample_rate = 1.0
end
