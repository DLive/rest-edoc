# rest_edoc
	Rest_edoc 是一个 restful api 文档生成器，面向 swagger-ui.

# Start
修改 rebar.conf
```
{deps, [
	{rest_edoc,".*",{git,"git@github.com:DLive/rest-edoc.git",{branch,"master"}}}
	]}.
{plugins, [rest_edoc]}.

{redoc_opts,[
	{target_dir,{your_application,"priv"}}
]}.
```
执行 rebar redoc
执行之后，就会在 your_application/priv目录生成swagger json文件

##示例
#### 模块说明
```
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
```

#### 函数
```
%% @path /{wxid}/wx
%% @tags wechat
%% @method get
%% @summary 公众号认证接口.
%% @description 公众号认证接口
%% @parameter wxid path string string true 微信公众号ID
%% @parameter echostr query string string true 输出字符串 defaultValue
%% @parameter signature query string string true 签名
%% @parameter timestamp query string string true 时间戳
%% @parameter nonce query string string true nonce
%% @parameter2 name=content in=body description="用户信息" required=true schema_$ref=registerinfo 
%% @responses id=default type=schema  schema_$ref=Productabc description=description
```
参考说明
@parameter 变量名  变量类型  值类型 格式化类型 是否必需要 说明 默认值
@parameter2 name=content in=body description="用户信息" required=true schema_$ref=registerinfo 

#### 返回值定义
```
%% @definition CustomName object
%% @propertie id=200 type=string description=descriptiondescriptiondescription
%% @propertie id=ref_other type=array items_$ref=Activity
```
参考说明
%% @definition 名称 类型

### 参考示例
example/example_req.erl