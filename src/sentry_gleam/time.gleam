//// UTC timestamp helpers. Gleam/stdlib has no RFC3339 formatter; delegate to OTP.

@external(erlang, "sentry_gleam_ffi", "rfc3339_now")
pub fn now_rfc3339() -> String
