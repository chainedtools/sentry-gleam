# Contributing to sentry-gleam

Thanks for helping out! This is an experimental SDK — expect rough edges.

## Setup

- Install the [Gleam toolchain](https://gleam.run) 1.3.0+ and Erlang/OTP 25+.
- `gleam deps download` then `gleam build`.

## Before submitting a PR

```bash
gleam build   # must compile without warnings
gleam check   # static check
gleam test    # all tests must pass
```

`gleam test` is offline — it covers DSN parsing, base64 handling, and
envelope serialization only. Never add tests that hit the network.

## Conventions

- MIT-licensed code, keep it that way.
- No secrets in commits: test DSNs must be synthetic (`example.com` hosts).
