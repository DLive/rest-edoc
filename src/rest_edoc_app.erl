-module(rest_edoc_app).

-behaviour(application).

%% Application callbacks
-export([start/2, stop/1]).

%% ===================================================================
%% Application callbacks
%% ===================================================================

start(_StartType, _StartArgs) ->
    rest_edoc_sup:start_link().

stop(_State) ->
    ok.
