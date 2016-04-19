
function addApiKeyAuthorization(){
	var key = encodeURIComponent($('#input_apiKey')[0].value);
	if(key && key.trim() != "") {
	    var apiKeyAuth = new SwaggerClient.ApiKeyAuthorization("api_key", key, "query");
	    window.swaggerUi.api.clientAuthorizations.add("api_key", apiKeyAuth);
	    log("added key " + key);
	}
}

function MoudleList (Opt){
	this.url=Opt.url;
	this.preEle=null;
	this.init();
}
// MoudleList.prototype.init=function(){
// 	// console.log(this.url);	
// 	$.ajax({
// 		url:this.url,
// 		dataType:"json",
// 		success:function(Data){
// 			console.log(Data);
// 			this.render();
// 		}
// 	})
// }
MoudleList.prototype={
	init:function(){
	// console.log(this.url);
		var self=this;
		$.ajax({
			url:this.url,
			dataType:"json",
			success:function(Data){
				// console.log(Data);
				self.render(Data);
			}
		});
	},
	render:function(Obj){
		var ul = $("#module_list_content");
		console.log(Obj);
		for(var key in Obj){
			var value = Obj[key];
			console.log(value);
			$("<li><a href='###' mvalue='"+key+"'>"+value+"</a></li>").appendTo(ul);
		}
		this.init_first_module(Obj);
		this.bindEvent();
	},
	init_first_module:function(Obj){
		for(var key in Obj){
			// var value = Obj[key];
			this.changeMoudleApi(key);
		}
	},
	bindEvent:function(){
		var self=this;
		$("#module_list_content").bind('click',function(Obj){
			var a =Obj.srcElement;
			var curmoudle = a.getAttribute('mvalue');
			self.changeMoudleApi(curmoudle);
			a.className="active";
			if(self.preEle!=null){
				self.preEle.className="";
			}
			self.preEle=a;
			// console.log(a.getAttribute('mvalue'));
		});
	},
	changeMoudleApi:function(MoudleName){
		// var sw = new SwaggerUi({
	 //        url: "http://isobig.com/static/"+MoudleName+".json",
	 //        dom_id: "swagger-ui-container",
	 //        supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
	 //        validatorUrl:"http://isobig.com/static",
	 //        onComplete: function(swaggerApi, swaggerUi){
	 //          if(typeof initOAuth == "function") {
	 //            initOAuth({
	 //              clientId: "your-client-id",
	 //              realm: "your-realms",
	 //              appName: "your-app-name"
	 //            });
	 //          }
	 //          $('pre code').each(function(i, e) {
	 //            hljs.highlightBlock(e)
	 //          });
	 //          addApiKeyAuthorization();
	 //        },
	 //        onFailure: function(data) {
	 //          console.log("Unable to Load SwaggerUI");
	 //        },
	 //        docExpansion: "none",
	 //        apisSorter: "alpha",
	 //        showRequestHeaders: true
	 //    });
	 //    sw.load();


	    if(window.SwaggerTranslator) {
       	 window.SwaggerTranslator.translate();
      	}
      	var sw  = new SwaggerUi({
	        url: "http://127.0.0.1:7080/"+MoudleName+".json",
	        dom_id: "swagger-ui-container",
	        supportedSubmitMethods: ['get', 'post', 'put', 'delete', 'patch'],
	        onComplete: function(swaggerApi, swaggerUi){
	          if(typeof initOAuth == "function") {
	            initOAuth({
	              clientId: "your-client-id",
	              clientSecret: "your-client-secret-if-required",
	              realm: "your-realms",
	              appName: "your-app-name",
	              scopeSeparator: ",",
	              additionalQueryStringParams: {}
	            });
	          }

	          if(window.SwaggerTranslator) {
	            window.SwaggerTranslator.translate();
	          }
	        },
	        onFailure: function(data) {
	          log("Unable to Load SwaggerUI");
	        },
	        docExpansion: "none",
	        jsonEditor: true,
	        defaultModelRendering: 'schema',
	        showRequestHeaders: true
      });

      sw.load();

	}
}
$(function () {
	$('#input_apiKey').change(addApiKeyAuthorization);
	new MoudleList({url:"/modulelist.json"});

});
