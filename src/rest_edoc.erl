-module(rest_edoc).

-export([redoc/2]).


redoc(Config,AppFile) ->
    % io:format("appfile:~p~n", [AppFile]),
    if
        AppFile == undefined ->
            {ok, Config};
        true ->
            IsRel = lists:suffix("reltool.config", AppFile),
            case IsRel of 
                true ->
                    {ok, Config};
                _->
                    EDocOpts = rebar_config:get(Config, redoc_opts, []),
                    {ok, Config1, AppName, _AppData} = rebar_app_utils:load_app_file(Config, AppFile),
                    % io:format("appinfo:~p", [AppName]),
                    restedoc:application(AppName,EDocOpts),
                    {ok, Config1}
            end
    end.