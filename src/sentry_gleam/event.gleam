//// Event types (Level, Event payload) — Gleam counterpart of the Zig SDK's
//// `types/Event.zig` + `types/Level.zig`.

import gleam/json.{type Json}
import gleam/option.{type Option, None, Some}
import sentry_gleam/time

pub type Level {
  Fatal
  Error
  Warning
  Info
  Debug
}

pub fn level_to_json(level: Level) -> Json {
  case level {
    Fatal -> json.string("fatal")
    Error -> json.string("error")
    Warning -> json.string("warning")
    Info -> json.string("info")
    Debug -> json.string("debug")
  }
}

pub type ExceptionEntry {
  ExceptionEntry(kind: String, value: String)
}

pub type Event {
  Event(
    event_id: String,
    level: Level,
    message: Option(String),
    exception: Option(ExceptionEntry),
    environment: String,
    release: String,
  )
}

/// Serialize the event payload (Store Event / Envelope item body).
pub fn event_to_json(event: Event) -> Json {
  let message_json = case event.message {
    Some(message) ->
      json.object([#("message", json.object([#("formatted", json.string(message))]))])
    None -> json.null()
  }
  let exception_json = case event.exception {
    Some(ExceptionEntry(kind, value)) ->
      json.object([
        #(
          "values",
          json.array(
            [
              json.object([#("type", json.string(kind)), #("value", json.string(value))]),
            ],
            fn(item) { item },
          ),
        ),
      ])
    None -> json.null()
  }
  json.object([
    #("event_id", json.string(event.event_id)),
    #("platform", json.string("gleam")),
    #("level", level_to_json(event.level)),
    #("message", message_json),
    #("exception", exception_json),
    #("environment", json.string(event.environment)),
    #("release", json.string(event.release)),
    #("timestamp", json.string(time.now_rfc3339())),
  ])
}
