-module(sentry_gleam_ffi).
-export([rfc3339_now/0, getenv/1]).

rfc3339_now() ->
    Ts = calendar:system_time_to_rfc3339(erlang:system_time(second),
                                         [{unit, second}]),
    unicode:characters_to_binary(Ts).

getenv(Var) ->
    case os:getenv(unicode:characters_to_list(Var)) of
        false -> {error, nil};
        Value -> {ok, unicode:characters_to_binary(Value)}
    end.
