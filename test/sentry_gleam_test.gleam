import gleam/bit_array
import gleam/int
import gleam/json
import gleam/option.{None, Some}
import gleam/string
import gleeunit
import gleeunit/should
import sentry_gleam/client
import sentry_gleam/config.{Config}
import sentry_gleam/dsn
import sentry_gleam/envelope
import sentry_gleam/event.{Event, Info, Warning}

pub fn main() {
  gleeunit.main()
}

// ---- DSN parsing (mirrors the Zig SDK's Dsn tests) ----

pub fn dsn_parse_basic_test() {
  let assert Ok(parsed) = dsn.parse("https://public@sentry.example.com/1")
  parsed.scheme |> should.equal("https")
  parsed.host |> should.equal("sentry.example.com")
  parsed.port |> should.equal(443)
  parsed.public_key |> should.equal("public")
  parsed.secret_key |> should.equal(None)
  parsed.project_id |> should.equal("1")
  parsed.path |> should.equal("/")
}

pub fn dsn_parse_secret_port_test() {
  let assert Ok(parsed) =
    dsn.parse("http://public:secret@example.com:8080/path/42")
  parsed.scheme |> should.equal("http")
  parsed.host |> should.equal("example.com")
  parsed.port |> should.equal(8080)
  parsed.public_key |> should.equal("public")
  let assert Some(secret) = parsed.secret_key
  secret |> should.equal("secret")
  parsed.project_id |> should.equal("42")
  parsed.path |> should.equal("/path/")
}

pub fn dsn_parse_ingest_format_test() {
  let assert Ok(parsed) =
    dsn.parse("https://abc123def456@o12345.ingest.sentry.io/6789")
  parsed.host |> should.equal("o12345.ingest.sentry.io")
  parsed.public_key |> should.equal("abc123def456")
  parsed.project_id |> should.equal("6789")
}

pub fn dsn_parse_base64_url_test() {
  let encoded =
    bit_array.from_string("https://key@example.com/1")
    |> bit_array.base64_encode(False)
  let assert Ok(parsed) = dsn.parse(encoded)
  parsed.host |> should.equal("example.com")
  parsed.public_key |> should.equal("key")
}

pub fn dsn_parse_base64_public_key_test() {
  // Non-32-hex keys are treated as possibly base64-encoded.
  let encoded =
    bit_array.from_string("key12345abc!")
    |> bit_array.base64_encode(False)
  let assert Ok(parsed) = dsn.parse("https://" <> encoded <> "@example.com/1")
  parsed.public_key |> should.equal("key12345abc!")
}

pub fn dsn_error_cases_test() {
  dsn.parse("not a dsn") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("https://") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("https://key@host") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("https://:secret@host/1") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("ftp://key@host/1") |> should.equal(Error(dsn.BadDsn))
  dsn.parse("https://key@host:zz/1") |> should.equal(Error(dsn.BadDsn))
}

pub fn store_url_test() {
  let assert Ok(parsed) = dsn.parse("https://key@sentry.example.com/sub/123")
  dsn.store_url(parsed)
  |> should.equal("https://sentry.example.com/sub/api/123/store/")
}

pub fn envelope_url_test() {
  let assert Ok(parsed) = dsn.parse("https://key@sentry.example.com/123")
  dsn.envelope_url(parsed)
  |> should.equal("https://sentry.example.com/api/123/envelope/")
}

pub fn store_url_explicit_port_test() {
  let assert Ok(parsed) = dsn.parse("http://key@example.com:8080/1")
  dsn.store_url(parsed)
  |> should.equal("http://example.com:8080/api/1/store/")
}

pub fn auth_header_test() {
  let assert Ok(parsed) = dsn.parse("https://key@example.com/1")
  dsn.auth_header(parsed)
  |> should.equal(
    "Sentry sentry_key=key, sentry_version=7, sentry_client=sentry_gleam/0.1.0",
  )
}

pub fn dsn_roundtrip_test() {
  let original = "https://public:secret@example.com:8080/path/42"
  let assert Ok(parsed) = dsn.parse(original)
  dsn.to_string(parsed) |> should.equal(original)
}

// ---- Event / envelope serialization (no network) ----

pub fn event_serialization_test() {
  let e =
    Event(
      event_id: "1234567890abcdef1234567890abcdef",
      level: Info,
      message: Some("hello from gleam"),
      exception: None,
      environment: "production",
      release: "1.0.0",
    )
  let body = json.to_string(event.event_to_json(e))
  should.be_true(string.contains(body, "\"platform\":\"gleam\""))
  should.be_true(string.contains(body, "\"level\":\"info\""))
  should.be_true(string.contains(
    body,
    "\"message\":{\"formatted\":\"hello from gleam\"}",
  ))
  should.be_true(string.contains(body, "\"environment\":\"production\""))
}

pub fn exception_serialization_test() {
  let e =
    Event(
      event_id: "1234567890abcdef1234567890abcdef",
      level: event.Error,
      message: None,
      exception: Some(event.ExceptionEntry("ErlangError", "badarg")),
      environment: "test",
      release: "",
    )
  let body = json.to_string(e |> event.event_to_json)
  should.be_true(string.contains(
    body,
    "\"values\":[{\"type\":\"ErlangError\",\"value\":\"badarg\"}]",
  ))
}

fn test_client() {
  client.new(Config(
    dsn: "https://key@sentry.example.com/1",
    environment: "test",
    release: "0.0.1",
  ))
}

pub fn client_new_validates_dsn_test() {
  let assert Ok(_) = test_client()
  client.new(Config(dsn: "not a dsn", environment: "test", release: "0.0.1"))
  |> should.equal(Error(client.InvalidDsn))
}

fn is_ok(result) {
  case result {
    Ok(_) -> True
    Error(_) -> False
  }
}

pub fn unused_marker_test() {
  is_ok(test_client()) |> should.be_true
}

pub fn envelope_framing_test() {
  let assert Ok(c) = test_client()
  let e =
    Event(
      event_id: "1234567890abcdef1234567890abcdef",
      level: Warning,
      message: Some("test message"),
      exception: None,
      environment: "test",
      release: "0.0.1",
    )
  let body = envelope.build(e, dsn.to_string(c.parsed))
  // header line \n item header line \n payload line \n
  let assert [header, item, payload, ""] = string.split(body, "\n")
  should.be_true(string.contains(header, "\"event_id\""))
  should.be_true(string.contains(item, "\"type\":\"event\""))
  should.be_true(string.contains(item, "\"content_type\":\"application/json\""))
  let payload_size =
    bit_array.byte_size(bit_array.from_string(payload))
    |> int.to_string
  should.be_true(string.contains(item, "\"length\":" <> payload_size))
  should.be_true(string.contains(payload, "\"level\":\"warning\""))
}

/// Serialize the payload a client would build, without network side effects.
pub fn client_event_serialization_test() {
  let assert Ok(c) = test_client()
  let body = client.serialize_event(c, "captured", Warning)
  should.be_true(string.contains(body, "\"level\":\"warning\""))
  should.be_true(string.contains(
    body,
    "\"message\":{\"formatted\":\"captured\"}",
  ))
}
