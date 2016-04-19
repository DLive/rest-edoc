-module(example_req).

-export([init/0]).

-record(state,{
        prefix,
        dispatcher
    }).

%  @info
%% @title 微信接口
%% @description 对接微信公众平台接口
%% @version 1.0.0
%% @host isobig.com
%% @schemes http
%% @basePath /wechat
%% @produces application/json
%% @tag wechat 微信公用
%% @tag wechat2 微信私有

%% @definition Productabc object
%% @propertie id=200 type=string description=descriptiondescriptiondescription
%% @propertie id=ref_other type=array items_$ref=Activity
init() ->
    
    {ok, #state{}}.


%% @path /{wxid}/wx
%% @tags wechat
%% @method get
%% @summary 公众号认证接口.
%% @description 公众号认证接口,需要传递公众号ID
%% @parameter wxid path string string true 微信公众号ID
%% @parameter echostr query string string true 输出字符串 defaultValue
%% @parameter signature query string string true 签名
%% @parameter timestamp query string string true 时间戳
%% @parameter nonce query string string true nonce
%% @responses id=default type=schema  schema_$ref=Productabc description=description


process_request("wx/get",WeAppid,RequestInfo, Request,_Timeout) ->
    ok;

%% @path /{wxid}/wx
%% @tags wechat
%% @method post
%% @summary 公众号认证接口.
%% @consumes application/json,application/xml
%% @produces application/json,application/xml
%% @description 公众号认证接口,需要传递公众号ID
%% @parameter wxid path string string true 微信公众号ID
%% @parameter wxcontent body string string true 传递消息内容
%% @responses id=default type=schema  schema_$ref=Productabc description=description

process_request("wx/post",WeAppid,_RequestInfo, Request,_Timeout) ->
    ok.
