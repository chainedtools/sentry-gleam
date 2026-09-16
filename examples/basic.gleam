//// Basic example: configure, init the client, capture a message and an
//// exception using the real network (requires a valid DSN).
////
//// Run with:
////   SENTRY_DSN="https://key@sentry.example.com/1" gleam run -m examples/basic

import gleam/io
import sentry_gleam
import sentry_gleam/config.{Config}
import sentry_gleam/env
import sentry_gleam/event

pub fn main() {
  let assert Ok(dsn) = env.lookup("SENTRY_DSN")

  let assert Ok(client) =
    sentry_gleam.new(Config(
      dsn: dsn,
      environment: "development",
      release: "0.1.0",
    ))

  let assert Ok(event_id) =
    sentry_gleam.capture_message(
      client,
      "Application started successfully",
      event.Info,
    )
  io.println("sent message event: " <> event_id)

  let assert Ok(event_id) =
    sentry_gleam.capture_exception(client, "ErlangError", "badarg")
  io.println("sent exception event: " <> event_id)
}
