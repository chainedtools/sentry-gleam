//// HTTP ingest transport. Counterpart of the Zig SDK's `transport.zig` +
//// `types/TransportResult.zig` — maps network/response outcomes to a single
//// typed `SendError`.

import gleam/http
import gleam/http/request
import gleam/httpc
import sentry_gleam/dsn

pub type SendError {
  InvalidDsn(dsn.DsnError)
  NetworkFailure(String)
  Rejected(status: Int, body: String)
}

pub type Endpoint {
  Store
  Envelope
}

fn path_for(dsn: dsn.Dsn, endpoint: Endpoint) -> String {
  case endpoint {
    Store -> dsn.path <> "api/" <> dsn.project_id <> "/store/"
    Envelope -> dsn.path <> "api/" <> dsn.project_id <> "/envelope/"
  }
}

fn content_type(endpoint: Endpoint) -> String {
  case endpoint {
    Store -> "application/json"
    Envelope -> "application/x-sentry-envelope"
  }
}

/// POST a body to the DSN-derived ingest endpoint.
/// Returns the HTTP status on success.
pub fn send(
  dsn: dsn.Dsn,
  endpoint: Endpoint,
  auth: String,
  body: String,
) -> Result(Int, SendError) {
  let req =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_host(dsn.host)
    |> request.set_port(dsn.port)
    |> request.set_path(path_for(dsn, endpoint))
    |> request.set_header("x-sentry-auth", auth)
    |> request.set_header("content-type", content_type(endpoint))
  case httpc.send(request.Request(..req, body: body)) {
    Ok(resp) ->
      case resp.status >= 200 && resp.status < 300 {
        True -> Ok(resp.status)
        False -> Error(Rejected(resp.status, resp.body))
      }
    Error(_) -> Error(NetworkFailure("http client request failed"))
  }
}
