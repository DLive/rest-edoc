-module(apidoc_swagger).

-export([swagger_version/1,info/3,host/1,basepath/1,tags/2,add_tags/3,schemes/1,path_add_type/10,add_path/2]).


swagger_version(Ver)->
	{swagger,Ver}.

info(Description,Ver,Title)->
	{info,{[
		{description,Description}
		,{version,Ver}
		,{title,Title}
	]}}.
host(Host)->
	{host,Host}.

basepath(Path)->
	{basePath,Path}.

tags(Name,Description)->
	{tags,[{[
		{name,Name},
		{description,Description}
	]}]}.

add_tags(Tags,Name,Description) ->
	case Tags of
		{tags,List} ->
			List2 = List ++ [{[
				{name,Name},
				{description,Description}
			]}],
			{tags,List2};
		_ ->
			{tags,[{[
				{name,Name},
				{description,Description}
			]}]}
	end.

schemes(Schemes)->
	{schemes,[Schemes]}.

path_add_type(Path,Type,Tags,Summary,Description,OperationID,Consumes,Produces,Parameters,Responses)->
	case Path of
		{PathName,{PathInfoList} } ->
			PathInfoListNew = PathInfoList ++ [
				{Type,{[
					{tags,Tags},
					{summary,Summary},
					{description,Description},
					{operationId,OperationID},
					{consumes,Consumes},
					{produces,Produces},
					{parameters,Parameters},
					{responses,Responses}
					]}
				}
			],
			{PathName,
				{PathInfoListNew}
			};
		_ ->
			{Path,
				{[
					{Type,{[
						{tags,Tags},
						{summary,Summary},
						{description,Description},
						{operationId,OperationID},
						{consumes,Consumes},
						{produces,Produces},
						{parameters,Parameters},
						{responses,Responses}
						]}
					}
				]}
			}
	end.

add_path(PathList,Path) ->
	case PathList of
		{paths,{List}} ->
			{paths,{
				List ++ [Path]
			}};
		_ ->
			{paths,{
				[Path]
			}}
	end.
