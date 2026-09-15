//// Public surface of the SDK. Submodules are directly importable for
//// advanced use (DSN parsing, envelope framing, transport).

import sentry_gleam/client
import sentry_gleam/config
import sentry_gleam/event

/// Validate the DSN and create a client.
pub fn new(config: config.Config) -> Result(client.Client, client.CaptureError) {
  client.new(config)
}

/// Capture a message with a severity level.
pub fn capture_message(
  c: client.Client,
  message: String,
  level: event.Level,
) -> Result(String, client.CaptureError) {
  client.capture_message(c, message, level)
}

/// Capture an exception by type and value.
pub fn capture_exception(
  c: client.Client,
  kind: String,
  value: String,
) -> Result(String, client.CaptureError) {
  client.capture_exception(c, kind, value)
}
