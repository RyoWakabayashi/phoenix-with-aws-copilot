import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sample_app, SampleAppWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "hOwaFmD8HLK2ezi2hRJjucMV0N+s/2kJnKOoM6ubnTF5G6la7GQEhshmxPx0NrhM",
  server: false

# In test we don't send emails.
config :sample_app, SampleApp.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
