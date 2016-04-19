-module(rest_example).

-export([start/0]).

start()->
	Dispatch = cowboy_router:compile([
		{'_', [
			{"/", cowboy_static, {priv_file, doc_example, "index.html"}},
			{"/[...]", cowboy_static, {priv_dir, doc_example, "",
				[{mimetypes, cow_mimetypes, all}]}}
		]}
	]),
	{ok, _} = cowboy:start_http(http, 100, [{port,7080}], [
		{env, [{dispatch, Dispatch}]}
	]),
	io:format("example server is start with port ~p~n", [7080]),
	ok.