//// Client with `capture_message` / `capture_exception` entry points.
//// Counterpart of `client.zig` in the Zig SDK.

import gleam/bit_array
import gleam/json
import gleam/option.{None, Some}
import sentry_gleam/config.{type Config}
import sentry_gleam/dsn
import sentry_gleam/envelope
import sentry_gleam/event.{ExceptionEntry, Event}
import sentry_gleam/transport

pub type Client {
  Client(config: Config, parsed: dsn.Dsn)
}

pub type CaptureError {
  InvalidDsn
  SendFailed(transport.SendError)
}

/// Create a client, validating the DSN up front.
pub fn new(config: Config) -> Result(Client, CaptureError) {
  case dsn.parse(config.dsn) {
    Ok(parsed) -> Ok(Client(config: config, parsed: parsed))
    Error(_) -> Error(InvalidDsn)
  }
}

/// Capture a message with a severity level. Returns the event id.
pub fn capture_message(
  client: Client,
  message: String,
  level: event.Level,
) -> Result(String, CaptureError) {
  capture(client, Some(message), None, level)
}

/// Capture an exception by type + value (e.g. Erlang error class and reason).
pub fn capture_exception(
  client: Client,
  kind: String,
  value: String,
) -> Result(String, CaptureError) {
  capture(client, None, Some(ExceptionEntry(kind: kind, value: value)), event.Error)
}

fn capture(
  client: Client,
  message: option.Option(String),
  exception: option.Option(event.ExceptionEntry),
  level: event.Level,
) -> Result(String, CaptureError) {
  let e = Event(
    event_id: new_event_id(),
    level: level,
    message: message,
    exception: exception,
    environment: client.config.environment,
    release: client.config.release,
  )
  let body = envelope.build(e, dsn.to_string(client.parsed))
  case
    transport.send(client.parsed, transport.Envelope, dsn.auth_header(client.parsed), body)
  {
    Ok(_) -> Ok(e.event_id)
    Error(error) -> Error(SendFailed(error))
  }
}

/// Random event id — OTP crypto's strong bytes, hex encoded.
@external(erlang, "crypto", "strong_rand_bytes")
fn strong_rand_bytes(n: Int) -> BitArray

fn new_event_id() -> String {
  bit_array.base16_encode(strong_rand_bytes(16))
}

/// Serialize the event payload for an unconditional message capture;
/// exposed for testing without network side effects.
pub fn serialize_event(
  client: Client,
  message: String,
  level: event.Level,
) -> String {
  let e = Event(
    event_id: "0123456789abcdef0123456789abcdef",
    level: level,
    message: Some(message),
    exception: None,
    environment: client.config.environment,
    release: client.config.release,
  )
  json.to_string(e |> event.event_to_json)
}
