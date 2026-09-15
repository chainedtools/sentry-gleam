//// Environment variable lookup (Erlang/OTP target).

import gleam/option.{type Option, None, Some}

@external(erlang, "sentry_gleam_ffi", "getenv")
pub fn lookup(variable: String) -> Result(String, Nil)

/// Like `lookup`, as an Option.
pub fn get(variable: String) -> Option(String) {
  case lookup(variable) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}
