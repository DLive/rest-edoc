-module(user_req).
%% cloudi_service callbacks
-export([cloudi_service_init/4,
         cloudi_service_handle_request/11,
         cloudi_service_handle_info/3,
         cloudi_service_terminate/3]).


-record(state,
    {
        prefix,
        dispatcher
    }).

%  @info
%% @title 用户相关
%% @description 对接用户相关操作，用户基础信息管理，微信用户管理，用户组管理，会话管理，登录
%% @version 1.0.0
%% @host localhost:7080
%% @schemes http
%% @basePath /user
%% @produces application/json
%% @tag user 用户基础
%% @tag wechat 微信基础
%% @tag group 用户组管理
%% @tag login 登录操作
%% @tag session 会话操作
%% @tag cache 缓存操作

%% @definition registerinfo object
%% @propertie id=username type=string description=用户名
%% @propertie id=password type=string description=密码

%% @definition commont_result object
%% @propertie id=code type=integer description=状态码
%% @propertie id=message type=string description=返回消息内容


cloudi_service_init(_Args, Prefix, _Timeout,Dispatcher) ->
    
    {ok, #state{}}.

cloudi_service_handle_request(_Type, Name, _Pattern, _RequestInfo, Request,
                              _Timeout, _Priority, _TransId, _Pid,
                              #state{prefix=Prefix} = State, Dispatcher) ->
    ok.

cloudi_service_handle_info(Request, State, _) ->
    {noreply, State}.

cloudi_service_terminate(_,_Timeout, _State) ->
    ok.


%% @path /session
%% @tags session
%% @method put
%% @summary 修改会话信息.
%% @description 修改会话信息,将新值替换旧值
%% @parameter token header string string true 用户会话标识 2415901612564febbcc3cb63d2b155a7
%% @parameter content body string string true 内容值
%% @responses id=200 type=object  description=返回设置内容
process_request("/session/put",RequestInfo, Request,_Timeout, _Priority, _TransId, _Pid,_State,Dispatcher) ->
    ok;

%% @path /session
%% @tags session
%% @method post
%% @summary 创建会话信息.
%% @description 创建会话信息
%% @parameter token header string string true 用户会话标识 2415901612564febbcc3cb63d2b155a7
%% @parameter content body string string true 内容值
%% @responses id=200 type=object  description=返回设置内容
process_request("/session/post",RequestInfo, Request,_Timeout, _Priority, _TransId, _Pid,_State,Dispatcher) ->
    ok;

%% @path /session
%% @tags session
%% @method get
%% @summary 获取会话信息.
%% @description 获取会话信息
%% @parameter token header string string true 用户会话标识 2415901612564febbcc3cb63d2b155a7
%% @responses id=200 type=object  description=返回设置内容
process_request("/session/get",RequestInfo, Request,_Timeout, _Priority, _TransId, _Pid,_State,Dispatcher) ->
    ok.
