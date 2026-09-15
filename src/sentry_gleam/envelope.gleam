//// Envelope serialization (Envelope API item framing). Mirror of
//// `types/SentryEnvelope.zig` in the Zig SDK.
////
//// Wire format: envelope header \n item header \n item payload \n

import gleam/bit_array
import gleam/json
import sentry_gleam/event.{type Event}
import sentry_gleam/time

pub fn build(event: Event, dsn_string: String) -> String {
  let payload = json.to_string(event.event_to_json(event))
  let payload_size = bit_array.byte_size(bit_array.from_string(payload))
  let header =
    json.to_string(
      json.object([
        #("event_id", json.string(event.event_id)),
        #("sent_at", json.string(time.now_rfc3339())),
        #("dsn", json.string(dsn_string)),
      ]),
    )
  let item_header =
    json.to_string(
      json.object([
        #("type", json.string("event")),
        #("content_type", json.string("application/json")),
        #("length", json.int(payload_size)),
      ]),
    )
  header <> "\n" <> item_header <> "\n" <> payload <> "\n"
}
