//// Client configuration — counterpart of `types/SentryOptions.zig`.

pub type Config {
  Config(dsn: String, environment: String, release: String)
}
