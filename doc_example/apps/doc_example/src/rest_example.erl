-module(rest_example).

-export([start/0]).

start()->
	ok = application:start(crypto),
	ok = application:start(ranch),
	ok = application:start(jiffy),
	ok = application:start(cowlib),
	ok = application:start(cowboy),

	Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, doc_example, "index.html"}},
            {"/[...]", cowboy_static, {priv_dir, doc_example, "",[{mimetypes, cow_mimetypes, all}]}}
		]}
	]),
	{ok, _} = cowboy:start_http(httptest, 100, [{port,7080}], [
		{env, [{dispatch, Dispatch}]}
	]),
	io:format("example server is start with port ~p~n", [7080]),
	ok.