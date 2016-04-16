-module(restedoc_comment).

-export([comment/1,scan_line_item/1]).

-include("restedoc_doclet.hrl").

-record(tag, {name, line = 0, origin = comment, data}).
-record(module_info, {tag = value}).
comment(File)->
	Comment = edoc:read_comments(File),

	ModuleView = lists:foldl(fun ({_,_,_,List},OverView)-> 
            TagList = filter_tag_content(List),
            TagListType = check_tag_type(TagList),
            {_,NewView} = parse_comments_tag(TagListType,TagList,OverView),
            NewView
        end, #module_view{}, Comment),
    {ok,ModuleView}.
    
	
parse_comments_tag(function,TagList,OverView)->
    {ok,RE} = re:compile("[\s\t,]"),
    Path = unicode:characters_to_binary(proplists:get_value(path, TagList, "/unknow")),
    Method = unicode:characters_to_binary( proplists:get_value(method, TagList, "get")),
    Tags = unicode:characters_to_binary( proplists:get_value(tags, TagList, "DefaultTag") ),
    Summary = unicode:characters_to_binary( proplists:get_value(summary, TagList, "unknow summary") ),
    Description = unicode:characters_to_binary( proplists:get_value(description, TagList, "unknow Description") ),
    Consumes = split_by(RE,unicode:characters_to_binary( proplists:get_value(consumes, TagList, "application/json"))), 
    Produces = split_by(RE,unicode:characters_to_binary( proplists:get_value(produces, TagList, "application/json"))),
    Parameter =parse_fun_para_list(TagList),
    Responses = parse_responses_tag(TagList),
    case Path of 
        <<"/user">> ->
            io:format("will add userinfo~n");
        _ ->
            ok 
    end,
    restedoc_apidoc:add_path(Tags,Method,Path,Parameter,Responses,Summary,Description,Consumes,Produces),
    {function,OverView};

parse_comments_tag(moduleview,TagList,OverView)->
    Title = unicode:characters_to_binary(proplists:get_value(title, TagList, "unknow Title")),
    Description = unicode:characters_to_binary(proplists:get_value(description, TagList, "unknow description")),
    Version = unicode:characters_to_binary(proplists:get_value(version, TagList, "unknow_version")),
    Host = unicode:characters_to_binary(proplists:get_value(host, TagList, "127.0.0.1")),
    Schemes = unicode:characters_to_binary(proplists:get_value(schemes, TagList, "http")),
    BasePath = unicode:characters_to_binary(proplists:get_value(basePath, TagList, "/")),
    Produces = unicode:characters_to_binary(proplists:get_value(produces, TagList, "application/json")),
    parse_tag_list(TagList),
    View = OverView#module_view{
        title=Title,description=Description,version = Version,host=Host,schemes=Schemes,basePath=BasePath,produces=Produces
    },
    {moduleview,View};
parse_comments_tag(definition,TagList,OverView)->
    Definition = proplists:get_value(definition, TagList, "defaultName object"),
    [NameItem,TypeItem] = scan_line_item(Definition),
    Name = unicode:characters_to_binary(NameItem),
    Type = unicode:characters_to_binary(TypeItem),
    ProertiInfo = parse_definition_list(TagList),
    DefinitionItem = #{<<"type">> => Type, <<"properties">> => ProertiInfo},
    ets:insert(api_doc_definition, {Name,DefinitionItem}),
    {definition,OverView};   
parse_comments_tag(unknow,TagList,OverView)->
    {unknow,OverView}.

split_by(RE,Data)->
    re:split(Data,RE,[]).

parse_tag_list(TagList)->
    {ok,RE} = re:compile("[\s\t]"),
    lists:foreach(fun ({Tag,Value}) ->
        if Tag == tag  ->
            List = re:split(unicode:characters_to_binary(Value),RE,[{parts,2}]),
            restedoc_apidoc:add_tag(lists:nth(1, List), lists:nth(2, List));
            true -> false
        end
        end, TagList),
    ok.

parse_fun_para_list(TagList) ->
    ParaList = lists:filter(fun ({Tag,_}) ->
        if Tag == parameter  -> true;
            Tag == parameter2 -> true;
            true -> false
        end
        end, TagList),
    {ok,RE} = re:compile("[\s\t]"),
    [ format_parameter_str(P,RE) || P <- ParaList].
    
format_parameter_str({parameter,Para},RE)->
    List = scan_line_item(Para),
    % List = re:split(unicode:characters_to_binary(Para),RE,[{parts,6}]),
    Ret = #{
        name        =>unicode:characters_to_binary(lists:nth(1, List)),
        in          =>unicode:characters_to_binary(lists:nth(2, List)),
        type        =>unicode:characters_to_binary(lists:nth(3, List)),
        format      =>unicode:characters_to_binary(lists:nth(4, List)),
        required    =>unicode:characters_to_binary(lists:nth(5, List)),
        description =>unicode:characters_to_binary(lists:nth(6, List))
    },
    case length(List) of 
        Len when Len >= 7 ->
            Ret#{default => unicode:characters_to_binary( lists:nth(7, List))};
        _ ->
            Ret 
    end;

format_parameter_str({parameter2,Para},RE)->
    List = scan_line_item(Para),
    % List = re:split(unicode:characters_to_binary(Data),RE,[]),
    {ok,RE2} = re:compile("="),
    ProperInfo = lists:foldl(fun(Proper,Acc)->
        ProperBin = unicode:characters_to_binary(Proper),
        [parse_propertie(RE2,ProperBin)]++Acc
    end, [], List),
    Ret = lists:foldl(fun({Key,Value},Acc)->
        case Key of
            <<"required">> ->
                Acc#{Key => Value};
            <<"schema_type">> ->
                Items = maps:get(<<"schema">>, Acc, #{}),
                Items2  = Items#{<<"type">> => Value},
                Acc#{<<"schema">> => Items2};
            <<"schema_$ref">> ->
                Items = maps:get(<<"schema">>, Acc, #{}),
                Items3 = Items#{<<"$ref">> => << <<"#/definitions/">>/binary,Value/binary>> },
                Acc#{<<"schema">> => Items3};
            _ ->
                Acc#{Key => Value}
        end
    end, #{}, ProperInfo),
    Ret.

parse_responses_tag(TagList) ->
    {ok,RE2} = re:compile("="),
    Ret = lists:foldl(fun({Tag,Value},Acc)->
            case Tag of 
                responses ->
                    {Id,ProperValue} = parse_responses_propertie(Value,RE2),
                    Acc#{Id => ProperValue};
                _ ->
                    Acc
            end
        end, #{}, TagList),
    Ret.
parse_responses_propertie(Data,REEque) ->
    List = scan_line_item(Data),

    % List = re:split(unicode:characters_to_binary(Data),RE,[]),
    ProperInfo = lists:foldl(fun(Proper,Acc)->
        ProperBin = unicode:characters_to_binary(Proper),
        KV = re:split(ProperBin,REEque,[]),
        [Key,Value] = KV,
        [{Key,Value}]++Acc
    end, [], List),
    Ret = lists:foldl(fun({Key,Value},{Id,Acc})->
        case Key of
            <<"id">> ->
                {Value,Acc};
            <<"schema_$ref">> ->
                Items = maps:get(<<"schema">>, Acc, #{}),
                Items2  = Items#{<<"$ref">> => << <<"#/definitions/">>/binary,Value/binary>> },
                {Id,Acc#{<<"schema">> => Items2} };
            _ ->
                {Id, Acc#{Key => Value}}
        end
    end, {undefined, #{} }, ProperInfo),
    Ret.    
%% ============
parse_definition_list(TagList) ->
    {ok,RE2} = re:compile("="),
    Ret = lists:foldl(fun({Tag,Value},Acc)->
            case Tag of 
                propertie ->
                    {Id,ProperValue} = parse_definition_propertie(Value,RE2),
                    Acc#{Id => ProperValue};
                _ ->
                    Acc
            end
        end, #{}, TagList),
    Ret.

parse_definition_propertie(Data,REEque) ->
    List = scan_line_item(Data),
    % List = re:split(unicode:characters_to_binary(Data),RE,[]),
    ProperInfo = lists:foldl(fun(Proper,Acc)->
        ProperBin = unicode:characters_to_binary(Proper),
        [parse_propertie(REEque,ProperBin)]++Acc
    end, [], List),
    Ret = lists:foldl(fun({Key,Value},{Id,Acc})->
        case Key of
            <<"id">> ->
                {Value,Acc};
            <<"$ref">> ->
                {Id,Acc#{<<"$ref">> => << <<"#/definitions/">>/binary,Value/binary>> }};
            <<"items_type">> ->
                Items = maps:get(<<"items">>, Acc, #{}),
                Items2  = Items#{<<"type">> => Value},
                {Id,Acc#{<<"items">> => Items2} };
            <<"items_$ref">> ->
                Items = maps:get(<<"items">>, Acc, #{}),
                Items3 = Items#{<<"$ref">> => << <<"#/definitions/">>/binary,Value/binary>> },
                {Id, Acc#{<<"items">> => Items3} };
            _ ->
                {Id, Acc#{Key => Value}}
        end
    end, {undefined, #{} }, ProperInfo),
    Ret.
parse_propertie(REEque,Proper)->
    List = re:split(Proper,REEque,[]),
    case length(List) of 
        2 -> ok;
        _ ->
            io:format("error propertie info:~p~n", [List]),
            exit("can't proceess Propertie")
    end,
    [Key,Value] = List,
    {Key,Value}.

filter_tag_content(CommentList)->
	Ts0 = scan_lines(CommentList, 1),
	Ts0.
scan_lines(Ss, L) ->
    scan_lines(Ss, L, []).

scan_lines([S | Ss], L, As) ->
    scan_lines(S, Ss, L, As);
scan_lines([], _L, As) ->
    lists:reverse(As).

scan_lines([$\s | Cs], Ss, L, As) -> 
    scan_lines(Cs, Ss, L, As);
scan_lines([$\t | Cs], Ss, L, As) -> 
    scan_lines(Cs, Ss, L, As);
scan_lines([$% | Cs], Ss, L, As) -> 
    scan_lines(Cs, Ss, L, As);
scan_lines([$@ | Cs], Ss, L, As) -> 
    scan_tag(Cs, Ss, L, As, []);
scan_lines(_, Ss, L, As) -> scan_lines(Ss, L + 1, As).

scan_tag([C | Cs], Ss, L, As, Ts) when C >= $a, C =< $z ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag([C | Cs], Ss, L, As, Ts) when C >= $A, C =< $Z ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag([C | Cs], Ss, L, As, Ts) when C >= $\300, C =< $\377,
					 C =/= $\327, C =/= $\367 ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag([$_ | Cs], Ss, L, As, Ts) ->
    scan_tag_1(Cs, Ss, L, As, [$_ | Ts]);
scan_tag(_Cs, Ss, L, As, _Ts) ->
    scan_lines(Ss, L + 1, As).    % not a valid name

scan_tag_1([C | Cs], Ss, L, As, Ts) when C >= $a, C =< $z ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag_1([C | Cs], Ss, L, As, Ts) when C >= $A, C =< $Z ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag_1([C | Cs], Ss, L, As, Ts) when C >= $0, C =< $9 ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag_1([C | Cs], Ss, L, As, Ts) when C >= $\300, C =< $\377,
					 C =/= $\327, C =/= $\367 ->
    scan_tag_1(Cs, Ss, L, As, [C | Ts]);
scan_tag_1([$_ | Cs], Ss, L, As, Ts) ->
    scan_tag_1(Cs, Ss, L, As, [$_ | Ts]);
scan_tag_1(Cs, Ss, L, As, Ts) ->
    scan_tag_2(Cs, Ss, L, As, Ts).


scan_tag_2([$\s | Cs], Ss, L, As, T) ->
    find_line_content(Cs,T,[],L,Ss,As);
    % scan_tag_lines(Ss, T, [Cs], L + 1, As);
scan_tag_2([$\t | Cs], Ss, L, As, T) ->
    find_line_content(Cs,T,[],L,Ss,As);
scan_tag_2([$: | Cs], Ss, L, As, T) ->
    find_line_content(Cs,T,[],L,Ss,As);
scan_tag_2(Line, Ss, L, As, T) ->
    find_line_content(Line,T,[],L,Ss,As).


find_line_content([$\s | Line],CurrentTag,LineContent,LineNum,CommentList,TagList)->
    find_line_content(Line,CurrentTag,LineContent,LineNum,CommentList,TagList);
find_line_content([$\t | Line],CurrentTag,LineContent,LineNum,CommentList,TagList)->
    find_line_content(Line,CurrentTag,LineContent,LineNum,CommentList,TagList);
find_line_content([$% | Line],CurrentTag,LineContent,LineNum,CommentList,TagList)->
    find_line_content(Line,CurrentTag,LineContent,LineNum,CommentList,TagList);    
find_line_content([$@ | Line],CurrentTag,LineContent,LineNum,CommentList,TagList)->
    NewTagList = [make_tag(CurrentTag, LineNum, LineContent) | TagList],
    scan_tag(Line, CommentList, LineNum + 1, NewTagList,[]);
find_line_content(Line,CurrentTag,LineContent,LineNum,[],TagList)->
    NewTagList = [make_tag(CurrentTag, LineNum, LineContent++Line) | TagList],
    scan_tag([], [], LineNum + 1, NewTagList,[]);
find_line_content(Line,CurrentTag,LineContent,LineNum,CommentList,TagList)->
    [NextLine | List ] = CommentList,
    find_line_content(NextLine,CurrentTag,LineContent++Line,LineNum,List,TagList).


make_tag(Cs, L, Ss) ->
    {list_to_atom(lists:reverse(Cs)),Ss}.


check_tag_type([])->
    unknow;
check_tag_type([{info,_} | _List]) ->
    moduleview;
check_tag_type([{title,_} | _List]) ->
    moduleview;
check_tag_type([{host,_} | _List]) ->
    moduleview;
check_tag_type([{method,_} | _List]) ->
    function;
check_tag_type([{parameter,_} | _List]) ->
    function;
check_tag_type([{responses,_} | _List]) ->
    function;
check_tag_type([{path,_} | _List]) ->
    function;
check_tag_type([{definition,_} | _List]) ->
    definition;
check_tag_type([{_T,_} | List])->
    check_tag_type(List).

scan_line_item(Line) ->
    lists:reverse(scan_line_item(Line,[],[])).

scan_line_item([],Cur,Items) ->
    case Cur of 
        [] ->
            Items;
        _ ->
            [lists:reverse(Cur)] ++ Items
    end;
scan_line_item([$" | Cs],Cur,Items) ->
    scan_line_quota_end(Cs,Cur,Items);
scan_line_item([$\s | Cs],Cur,Items) ->
    case Cur of 
        [] ->   scan_line_item(Cs,[],Items);
        _ -> scan_line_item(Cs,[],[lists:reverse(Cur)] ++ Items)
    end;
scan_line_item([$\t | Cs],Cur,Items) ->    
    case Cur of 
        [] ->   scan_line_item(Cs,[],Items);
        _ -> scan_line_item(Cs,[],[lists:reverse(Cur)] ++ Items)
    end;
scan_line_item([T| Cs],Cur,Items) ->    
    scan_line_item(Cs,[T] ++ Cur,Items).

scan_line_quota_end([],Cur,Items) ->
    case Cur of 
        [] -> Items;
        _ -> [lists:reverse(Cur)] ++ Items
    end;
scan_line_quota_end([$" | Cs],Cur,Items) ->
    scan_line_item(Cs,[],[lists:reverse(Cur)] ++ Items);

scan_line_quota_end([T | Cs],Cur,Items) ->
    scan_line_quota_end(Cs, [T] ++ Cur, Items).





