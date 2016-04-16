-module(restedoc_apidoc).


-include("restedoc.hrl").
% -include("restedoc_doclet.hrl").
%% API
-export([add_path/9,add_tag/2]).

-export([init/0,save_to_list/9,save_tag/2,generate_doc_json/1]).

-ifdef(TEST).
-compile([export_all]).
-endif.

-define(LOG_WARN (R1,R2), io:format(R1, R2) ).

init()->
	Delete = fun () ->
		ets:delete(api_doc_list),
		ets:delete(api_doc_tags),
		ets:delete(api_doc_definition)
	end,
	try Delete() of
		_ ->
			ok
	catch
		_:_ ->
			ok
	end,
	
    I1 = ets:new(api_doc_list, [public,named_table,{keypos,2} ]),
    % io:format("init ets api doc list info:~p~n", [I1]),
    ets:new(api_doc_tags, [public,named_table,{keypos,2} ]),
    ets:new(api_doc_definition, [public,named_table,{keypos,1} ]),
    init_modult_ets(),
    ok.
init_modult_ets()->
	case ets:info(api_module) of
		undefined ->
			ets:new(api_module, [public,named_table,{keypos,1}]),			
			ok;
		_ ->
			ok
	end,
	ok.
add_path(Prefix,Type,Path,Parameter,Response,Summary,Description,Consumes,Produces)->
	save_to_list(Prefix,Type,Path,Parameter,Response,Summary,Description,Consumes,Produces).

add_tag(Tag,Descript)->
	save_tag(Tag,Descript).

-spec save_to_list(Prefix::binary(),Type::binary(),Path::binary(),Parameter::list(),Response::any(),Summary::binary(),Description::any(),Consumes::list(),Produces::list() ) -> ok.
save_to_list(Prefix,Type,Path,Parameter,Response,Summary,Description,Consumes,Produces)->
	true = is_binary(Prefix),
	true = is_binary(Type),
	true = is_binary(Path),
	true = is_list(Parameter),
	% true = is_m(Response),
	true = is_binary(Summary),
	true = is_binary(Description),
	OperationID = <<Prefix/binary,"_",Path/binary,Type/binary>>,
	Value = #api_doc_list{
		operationid = OperationID,
		prefix = Prefix,
		type = Type,
		path = Path,
		parameter = Parameter,
		response = Response,
		summary = Summary,
		description = Description,
		consumes = Consumes, %[<<"application/json">>],
		produces = Produces %[<<"application/json">>]
	},
	Ret = ets:insert(api_doc_list, Value),
	io:format("ets insert ret:~p~n", [Ret]),
			ok.
	

-spec save_tag(Tag::binary(),Description::binary()) -> ok.
save_tag(Tag,Description) when is_binary(Tag) and is_binary(Description) ->
	ets:insert(api_doc_tags, #api_doc_tags{tag=Tag,description=Description}),
	ok;
save_tag(_Tag,_Description)->
	{error,"parameter is error"}.

generate_doc_json(OverView) ->
	Paths = fetch_api_list(ets:first(api_doc_list),[]),
	% io:format("look see see path:~p~n", [Paths]),
	Tags = ets:foldl(fun (X,Acc) ->
		apidoc_swagger:add_tags(Acc,X#api_doc_tags.tag,X#api_doc_tags.description)
		end, {tags,[]} , api_doc_tags), 
	% Tags = apidoc_swagger:tags(<<"user">>, <<"abc">>),
	Definitions = generate_definition(),
	Content = [apidoc_swagger:swagger_version(<<"2.0">>),
		apidoc_swagger:info(OverView#module_view.description, OverView#module_view.version, OverView#module_view.title),
		apidoc_swagger:host(OverView#module_view.host),
		apidoc_swagger:basepath(OverView#module_view.basePath),
		apidoc_swagger:schemes([OverView#module_view.schemes])
	],
	Content1 = case Tags of 
		{tags,[]} ->
			Content;
		_ ->
			Content ++ [Tags]
	end,
	{Content2,PathSize} = case Paths of 
		{paths,{[]}} ->
			{Content1,0};
		{paths,{PathList}} ->
			Size = lists:flatlength(PathList),
			{Content1 ++ [Paths],Size}
	end,
	JsonObj = {Content2 ++ [ {<<"definitions">>,Definitions} ]},
	% io:format("jsonobj:~p~n", [JsonObj]),
	Result = jiffy:encode(JsonObj,[pretty]),
	% io:format("json:~p~n", [Result]),
	{ok,Result,PathSize};



generate_doc_json(true) ->
	Tags = apidoc_swagger:tags(<<"user">>, <<"abc">>),
	Path1 = apidoc_swagger:path_add_type(<<"pet">>,<<"get">>, [<<"user">>], <<"desafa">>, 
						<<"asdfasdfafa">>,
						<<"adduser">>,
						[<<"application/json">>, <<"application/xml">>],
						[<<"application/json">>, <<"application/xml">>],
						[{[{in,<<"query">>},{name,<<"username">>},{type,<<"string">>},{description,<<"sdfasdfaf">>},{required,true}]}], 
						{[{<<"404">>,{[{description,<<"4044444444">>}]}}]}
						),
	JsonObj = {[apidoc_swagger:swagger_version(<<"2.0">>),
		apidoc_swagger:info(<<"asdfasdfa">>, <<"1.0">>, <<"apidoc">>),
		apidoc_swagger:host(<<"isobig.com:6467">>),
		apidoc_swagger:basepath(<<"v1/">>),
		Tags,
		apidoc_swagger:add_tags(Tags,<<"account">>, <<"fa">>),
		apidoc_swagger:schemes([<<"http">>]),
		apidoc_swagger:add_path([], Path1) 
	]},
	% io:format("jsonobj:~p~n", [JsonObj]),
	Result = jiffy:encode(JsonObj,[pretty]),
	io:format("json:~p~n", [Result]),
	{ok,Result}.

generate_definition() ->
	ets:foldl(fun ({Name,Define},Acc) ->
			Acc#{Name => Define}
		end, #{} , api_doc_definition).


fetch_api_list('$end_of_table',Paths)->
	case Paths of
		[] ->
			{paths,{[]}};
		_ ->
			Paths
	end;

fetch_api_list(Key,Paths)->
	KeyNew = ets:next(api_doc_list, Key),
	[ApiInfo] = ets:lookup(api_doc_list, Key),
	{AddPath,Paths2} = case check_path_same_del(Paths,ApiInfo#api_doc_list.path) of 
		{none,_} ->
			{ApiInfo#api_doc_list.path,Paths};
		{OldPath,TPaths} ->
			{OldPath,TPaths}
		end,
	Path = api_info_to_jsoninfo(AddPath,ApiInfo),
	PathList = apidoc_swagger:add_path(Paths2, Path),
	fetch_api_list(KeyNew,PathList).

api_info_to_jsoninfo(PathOrOldPath, ApiInfo)->
	Path1 = apidoc_swagger:path_add_type(PathOrOldPath,
						ApiInfo#api_doc_list.type,
						[ApiInfo#api_doc_list.prefix],
						ApiInfo#api_doc_list.summary, 
						ApiInfo#api_doc_list.description,
						ApiInfo#api_doc_list.operationid,
						ApiInfo#api_doc_list.consumes,
						ApiInfo#api_doc_list.produces,
						ApiInfo#api_doc_list.parameter,
						ApiInfo#api_doc_list.response
						),
	Path1.

check_path_same_del(PathList,PathName) ->
	case PathList of 
		{paths,{Paths}} ->
			case lists:keyfind(PathName,1,Paths) of 
				false ->
					{none,PathList};
				NeedPath ->
					PathList2 = lists:delete(NeedPath,Paths),					
					{NeedPath,{paths,{PathList2}}}
			end;
		_ ->
			{none,PathList}
	end.

-ifdef(TEST).
add_test()->
	save_to_list(<<"user">>,<<"post">>,<<"add">>,
		[{[{in,<<"query">>},{name,<<"username">>},{type,<<"string">>},{description,<<"sdfasdfaf">>},{required,true}]},
			{[{in,<<"query">>},{name,<<"password">>},{type,<<"string">>},{description,<<"sdfasdfaf">>},{required,true}]}
		],
		{[{<<"404">>,{[{description,<<"4044444444">>}]}}]},
		<<"adduser">>,<<"dafasdfasdfasfas">>,
		[<<"application/json">>],
		[<<"application/json">>]
		),
	save_to_list(<<"user">>,<<"post">>,<<"delete">>,
		[{[{in,<<"query">>},{name,<<"username">>},{type,<<"string">>},{description,<<"sdfasdfaf">>},{required,true}]},
			{[{in,<<"query">>},{name,<<"password">>},{type,<<"string">>},{description,<<"sdfasdfaf">>},{required,true}]}
		],
		{[{<<"404">>,{[{description,<<"4044444444">>}]}}]},
		<<"adduser">>,<<"dafasdfasdfasfas">>,
		[<<"application/json">>],
		[<<"application/json">>]
		).
-endif.
	