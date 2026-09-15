# Experimental Sentry for Gleam

[![Build Status](https://img.shields.io/badge/build-passing-green)](https://github.com/getsentry/sentry-gleam)
[![Gleam Version](https://img.shields.io/badge/gleam-1.3.0+-blue)](https://gleam.run)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

Welcome to the experimental **Gleam SDK** for [**Sentry**](https://sentry.io).

> **⚠️ Experimental SDK**: This SDK is currently experimental and not production-ready. It was developed during a Hackweek project and is intended for testing and feedback purposes.

## 📦 Getting Started

### Prerequisites

You need:
- A [Sentry account and project](https://sentry.io/signup/)
- Gleam 1.3.0 or later (Erlang target)
- Erlang/OTP 25 or later

The Erlang SDK runtime is the usual [`gleam_http`](https://hexdocs.pm/gleam_http),
[`gleam_httpc`](https://hexdocs.pm/gleam_httpc), `gleam_json`, and `gleam_stdlib` set of Hex dependencies.

## 🚀 Installation

#### Using Gleam Package Manager (Recommended)

Add sentry-gleam to your project using the Gleam package manager:

```bash
# Add the dependency (replace with actual URL when published)
gleam add sentry_gleam
```

Then, import and use it:

```gleam
import sentry_gleam
```

### Basic Configuration

Here's a quick configuration example to get Sentry up and running:

```gleam
import gleam/env
import sentry_gleam
import sentry_gleam/config
import sentry_gleam/event

pub fn main() {
  let assert Ok(dsn) = env.get("SENTRY_DSN")

  let config =
    config.Config(
      dsn: dsn,
      environment: "production",
      release: "1.0.0",
    )
  let assert Ok(client) = sentry_gleam.new(config)

  // Your application code here...
  let assert Ok(_) = sentry_gleam.capture_message(
    client, "Application started with Sentry monitoring", event.Info,
  )
}
```

With this configuration, Sentry will monitor and capture event with the
provided DSN, environment, and release.

### Quick Usage Examples

#### Capturing Messages

```gleam
import sentry_gleam
import sentry_gleam/event

// After initializing the client...

// Capture messages with different severity levels
sentry_gleam.capture_message(client, "Application started successfully", event.Info)
sentry_gleam.capture_message(client, "Warning: Low memory", event.Warning)
sentry_gleam.capture_message(client, "Critical error occurred", event.Error)
sentry_gleam.capture_message(client, "System failure - immediate attention required", event.Fatal)
```

#### Capturing Exceptions

```gleam
import sentry_gleam

risky_operation()
|> fn(result) {
  case result {
    Ok(_) -> Ok(Nil)
    Error(error) ->
      case sentry_gleam.capture_exception(client, "GleamError", body_of(error)) {
        Ok(event_id) -> {
          print("Error sent to Sentry with ID: " <> event_id)
          Ok(Nil)
        }
        Err(_) -> Error(error)
      }
  }
}
```

## 🔧 Configuration Options

The `Config` type supports various configuration options:

```gleam
import sentry_gleam/config

let cfg = config.Config(
  dsn: "https://your-dsn@o0.ingest.sentry.io/0000000000000000", // DSN (optional base64-encoded public key / URL)
  environment: "production", // environment (development, staging, production)
  release: "1.2.3", // release version
)
```

The DSN parser is lenient:
- Standard DSNs (`https://key@host/project`) work out of the box.
- A base64-encoded DSN URL is decoded transparently.
- A base64-encoded public key is decoded transparently (plain keys that
  already look like Sentry's 32-char hex keys are used as-is).

## 🧩 Features

### Current Features
- ✅ **Event Capture**: Send custom events to Sentry
- ✅ **Message Capture**: Log messages with different severity levels
- ✅ **Exception Capture**: Capture exceptions by type and value
- ✅ **Envelope API + Store Event API**: Typed HTTP client wrapper POSTing to the DSN ingest endpoint
- ✅ **Error Mapping**: Network failures and rejected events mapped to a typed `SendError`
- ✅ **Release Tracking**: Track releases and environments
- ✅ **Testable Serialization**: Envelope framing covered by offline tests

### Upcoming Features
- 🔄 **Breadcrumbs**: Track user actions and application state
- 🔄 **User Context**: Attach user information to events
- 🔄 **Custom Tags**: Add custom tags to events
- 🔄 **Performance Monitoring**: Track application performance
- 🔄 **Integrations**: Common Gleam library integrations

## 📁 Examples

The repository includes a complete example in the `examples/` directory:

- **`basic.gleam`** - Demonstrates configuration, message capture, and exception capture

Run the example using:

```bash
# Build and run the basic example (requires a SENTRY_DSN)
SENTRY_DSN="https://your-dsn@example.ingest.sentry.io/1" gleam run -m examples/basic
```

## 🏗️ Building from Source

```bash
# Clone the repository
git clone https://github.com/getsentry/sentry-gleam.git
cd sentry-gleam

# Build the library
gleam build

# Run typechecks
gleam check

# Run tests
gleam test
```

## 🧪 Testing

This SDK is experimental. When testing:

1. Set up a test Sentry project (don't use production)
2. Run the example with debug logging enabled
3. Check your Sentry dashboard for captured events
4. Review the example for best practices

Note: `gleam test` only runs serialization / parsing tests and never
makes network calls.

## 🚧 Development Status

**Current Status**: Experimental / Hackweek Project

This SDK was built during a Sentry Hackweek and is not yet ready for production use. We're actively working on:

- Stabilizing the API
- Adding comprehensive tests
- Implementing missing features
- Performance optimizations
- Documentation improvements

## 🙌 Contributing

We welcome contributions! This is an experimental project and there's lots of room for improvement.

See [CONTRIBUTING.md](CONTRIBUTING.md) for details on getting started, or:

### Areas where we need help:
- 🐛 **Bug fixes** - Report issues or submit fixes
- ✨ **Features** - Implement missing Sentry features
- 📚 **Documentation** - Improve docs and examples
- 🧪 **Testing** - Add tests and improve coverage
- 🔍 **Code Review** - Review PRs and provide feedback

### Getting Started:
1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## 🛟 Support

- 📖 **Documentation**: [docs.sentry.io](https://docs.sentry.io)
- 💬 **Discord**: [Sentry Community Discord](https://discord.gg/sentry)
- 🐦 **Twitter/X**: [@getsentry](https://twitter.com/getsentry)
- 📧 **Issues**: [GitHub Issues](https://github.com/getsentry/sentry-gleam/issues)

## 📃 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## 🔗 Resources

- [Sentry Documentation](https://docs.sentry.io) - Complete Sentry documentation
- [Gleam Language](https://gleam.run) - Learn about the Gleam programming language
- [Sentry for Other Languages](https://docs.sentry.io/platforms/) - SDKs for other programming languages

## ⚠️ Disclaimer

This is an experimental SDK created during a Hackweek project. It is not officially supported by Sentry and should not be used in production environments without thorough testing and evaluation.

---

*Built with ❤️ during Sentry Hackweek*
