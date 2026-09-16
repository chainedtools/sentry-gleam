//// DSN parsing, mirroring the Zig SDK's `types/Dsn.zig`.

import gleam/bit_array
import gleam/int
import gleam/option.{type Option, None, Some}
import gleam/string

pub type DsnError {
  BadDsn
}

pub type Dsn {
  Dsn(
    scheme: String,
    host: String,
    port: Int,
    path: String,
    project_id: String,
    public_key: String,
    secret_key: Option(String),
  )
}

/// Parse a DSN string into its components.
///
/// Lenient variants accepted:
/// - a base64-encoded DSN URL (no scheme, standard alphabet only)
/// - a base64-encoded public key (anything that isn't the conventional
///   32-hex-character key is treated as possibly encoded and decoded)
pub fn parse(input: String) -> Result(Dsn, DsnError) {
  case string.contains(input, "://") {
    True -> parse_url(input)
    False ->
      case decode_b64(input) {
        Ok(decoded) -> parse_url(decoded)
        Error(_) -> Error(BadDsn)
      }
  }
}

fn parse_url(input: String) -> Result(Dsn, DsnError) {
  case split_once(input, "://") {
    Error(e) -> Error(e)
    Ok(#(scheme, rest)) ->
      case scheme == "http" || scheme == "https" {
        False -> Error(BadDsn)
        True -> {
          case split_once(rest, "@") {
            Error(e) -> Error(e)
            Ok(#(auth, rest)) ->
              case parse_auth(auth) {
                Error(e) -> Error(e)
                Ok(#(public_key, secret_key)) ->
                  case split_once(rest, "/") {
                    Error(e) -> Error(e)
                    Ok(#(host_port, rest)) ->
                      case parse_host_port(host_port, scheme) {
                        Error(e) -> Error(e)
                        Ok(#(host, port)) ->
                          case parse_path(rest) {
                            Error(e) -> Error(e)
                            Ok(#(path, project_id)) ->
                              Ok(Dsn(
                                scheme: scheme,
                                host: host,
                                port: port,
                                path: path,
                                project_id: project_id,
                                public_key: decode_public_key(public_key),
                                secret_key: secret_key,
                              ))
                          }
                      }
                  }
              }
          }
        }
      }
  }
}

fn parse_auth(auth: String) -> Result(#(String, Option(String)), DsnError) {
  let #(key, secret) = case split_once(auth, ":") {
    Ok(#(key, secret)) ->
      case secret == "" {
        True -> #(key, None)
        False -> #(key, Some(secret))
      }
    Error(_) -> #(auth, None)
  }
  case key == "" {
    True -> Error(BadDsn)
    False -> Ok(#(key, secret))
  }
}

fn parse_host_port(
  host_port: String,
  scheme: String,
) -> Result(#(String, Int), DsnError) {
  let default = case scheme {
    "https" -> 443
    _ -> 80
  }
  case split_once(host_port, ":") {
    Ok(#(host, port)) ->
      case int.parse(port) {
        Ok(port) -> Ok(#(host, port))
        Error(_) -> Error(BadDsn)
      }
    Error(_) -> Ok(#(host_port, default))
  }
}

fn parse_path(rest: String) -> Result(#(String, String), DsnError) {
  case rest == "" {
    True -> Error(BadDsn)
    False ->
      case split_last(rest, "/") {
        Ok(#(path, project_id)) -> Ok(#("/" <> path <> "/", project_id))
        Error(_) -> Ok(#("/", rest))
      }
  }
}

fn split_once(
  input: String,
  on: String,
) -> Result(#(String, String), DsnError) {
  case string.split_once(input, on) {
    Ok(pair) -> Ok(pair)
    Error(_) -> Error(BadDsn)
  }
}

fn split_last(input: String, on: String) -> Result(#(String, String), Nil) {
  case string.contains(input, on) {
    False -> Error(Nil)
    True -> do_split_last(input, on)
  }
}

fn do_split_last(input: String, on: String) -> Result(#(String, String), Nil) {
  case string.split_once(input, on) {
    Ok(#(prefix, tail)) ->
      case string.contains(tail, on) {
        True ->
          case do_split_last(tail, on) {
            Ok(#(p, last)) -> Ok(#(prefix <> on <> p, last))
            Error(_) -> Error(Nil)
          }
        False -> Ok(#(prefix, tail))
      }
    Error(_) -> Error(Nil)
  }
}

fn decode_b64(input: String) -> Result(String, Nil) {
  case bit_array.base64_decode(input) {
    Ok(bytes) -> bit_array.to_string(bytes)
    Error(_) -> Error(Nil)
  }
}

fn is_32_hex(value: String) -> Bool {
  case all_hex(string.to_graphemes(value)), string.length(value) == 32 {
    True, True -> True
    _, _ -> False
  }
}

fn all_hex(chars: List(String)) -> Bool {
  case chars {
    [] -> True
    [c, ..rest] ->
      case is_hex_char(c) {
        True -> all_hex(rest)
        False -> False
      }
  }
}

fn is_hex_char(c: String) -> Bool {
  case c {
    "0" | "1" | "2" | "3" | "4" | "5" | "6" | "7" | "8" | "9" -> True
    "a" | "b" | "c" | "d" | "e" | "f" -> True
    "A" | "B" | "C" | "D" | "E" | "F" -> True
    _ -> False
  }
}

fn decode_public_key(public_key: String) -> String {
  case is_32_hex(public_key), decode_b64(public_key) {
    True, _ -> public_key
    False, Ok(decoded) ->
      case string.length(decoded) > 0 {
        True -> decoded
        False -> public_key
      }
    False, Error(_) -> public_key
  }
}

/// Ingest endpoint for the Store Event API.
pub fn store_url(dsn: Dsn) -> String {
  base_url(dsn) <> "api/" <> dsn.project_id <> "/store/"
}

/// Ingest endpoint for the Envelope API.
pub fn envelope_url(dsn: Dsn) -> String {
  base_url(dsn) <> "api/" <> dsn.project_id <> "/envelope/"
}

fn base_url(dsn: Dsn) -> String {
  let netloc = case dsn.scheme, dsn.port {
    "https", 443 -> dsn.host
    "http", 80 -> dsn.host
    _, _ -> dsn.host <> ":" <> int.to_string(dsn.port)
  }
  dsn.scheme <> "://" <> netloc <> dsn.path
}

/// Reconstruct the DSN string.
pub fn to_string(dsn: Dsn) -> String {
  let netloc = case dsn.scheme, dsn.port {
    "https", 443 -> dsn.host
    "http", 80 -> dsn.host
    _, _ -> dsn.host <> ":" <> int.to_string(dsn.port)
  }
  case dsn.secret_key {
    Some(sk) ->
      dsn.scheme
      <> "://"
      <> dsn.public_key
      <> ":"
      <> sk
      <> "@"
      <> netloc
      <> dsn.path
      <> dsn.project_id
    None ->
      dsn.scheme
      <> "://"
      <> dsn.public_key
      <> "@"
      <> netloc
      <> dsn.path
      <> dsn.project_id
  }
}

/// X-Sentry-Auth header value for ingest requests.
pub fn auth_header(dsn: Dsn) -> String {
  "Sentry sentry_key="
  <> dsn.public_key
  <> ", sentry_version=7"
  <> ", sentry_client=sentry_gleam/0.1.0"
}
