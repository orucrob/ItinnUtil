part of itinnutil;
///Http Response object
class HttpResp{
  HttpRequest request;
  int status;
  bool success;
  List<ServerMsg> msg;
  var respObj;
}

///Server message object that is able to use as Mask Message object
class ServerMsg extends MaskMsg{
  ServerMsg(Code, Type, DefTxt): super(Code, Type, DefTxt);
  ServerMsg.fromJsonMap(Map jsonMap):super.fromJsonMap(jsonMap);
  static List<ServerMsg> transform(var jsonList){
    return MaskMsg.transform(jsonList);
  }
}


///Common server - implementation for common server tasks
class CommonServer extends Server{


  CommonServer():super();

  ///set users roles
  Future<HttpResp> setUserRoles(String userid, List<String> roles){
    var url = ctx.SERVER +"/api/profile/setuserroles?userid=${userid}";
    if(roles!=null){
      for(var role in roles){
        url += "&role=$role";
      }
    }
    return send2Token(url);
  }

  ///create new accout for user
  Future<HttpResp> createAccount(String userid, String password){
    var url = ctx.SERVER +"/api/account/create?login=${userid}&password=${password}";
    return send2Token(url);
  }
  ///create profile account
  Future<HttpResp> createProfileAccount(String userid, String password, [List<String> roles, String name] ){
    var url = ctx.SERVER +"/api/account/createinprofile?login=${userid}&password=${password}";
    if(roles!=null && roles.isNotEmpty){
      for(var i=1; i<=roles.length ; i++){
        url+="&role$i=${roles[i-1]}";
      }
    }
    if(name!=null && name!=""){
      url+="&name=${name}";
    }
    return send2Token(url);
  }

  ///remove user from profile - if profile account, it is removed
  Future<HttpResp> removeUserFromProfile(String userid){
    var url = ctx.SERVER +"/api/profile/removeuser?userid=${userid}";
    return send2Token(url);
  }
  ///login user
  Future<HttpResp> login(String userid, String password){
    var url = ctx.SERVER +"/api/account/login?login=${userid}&password=${password}";
    return send2(url);
  }
  ///logout user
  Future<HttpResp> logout(){
    var url = ctx.SERVER +"/api/account/logout";
    return send2Token(url);
  }

  ///get information about current logged user
  Future<HttpResp> userMe(){
    var url = ctx.SERVER +"/api/account/get";
    return send2Token(url);
  }
  ///delete user's account request
  Future<HttpResp> removeAccount(){
    var url = ctx.SERVER +"/api/account/remove";
    return send2Token(url);
  }

  Future<UserDO> syncMe(){
    var c = new Completer<UserDO>();
    userMe().then((HttpResp resp){
      var me = new UserDO();
      var profile = new ProfileDO();
      if(resp!=null && resp.success){
        me = _saveMe(resp, me);
        profile = _saveProfile(resp, profile);
        ctx.storage.settAction((sett){
          print('CHECK ME!');
          sett.me = me;
          sett.profile = profile;
          sett.token = resp.respObj['token'];
          sett.login = resp.respObj['login'];
        }).then((sett){
          c.complete(me);
        });
      }else{
        c.complete(me);
      }
    });
    return c.future;
  }

  static UserDO _saveMe(HttpResp resp, [UserDO me]){
    Map meM = resp.respObj['user'];
    if(meM!=null && meM.isNotEmpty){
      me = UserDO.fromJsonMap(meM, me);
    }
    return me==null? new UserDO():me;
  }
  static ProfileDO _saveProfile(HttpResp resp, [ProfileDO profile]){
    Map map = resp.respObj['profile'];
    if(map!=null && map.isNotEmpty){
      profile = ProfileDO.fromJsonMap(map, profile);
    }
    return profile == null ? new ProfileDO() : profile;
  }
}


abstract class Server{
  ItinnUtilContext ctx;
  Logger LOG;

  Server():super(){
    ctx = ItinnUtilContext.instance;
    LOG = ctx.LOG;
  }

  ///login user
  Future<HttpResp> loginWithToken(String token){
    var url = ctx.SERVER +"/api/account/login?token=${token}";
    return send2(url);
  }



  HttpResp _createResponse(HttpRequest req){
    HttpResp resp = new HttpResp();
    resp
    ..request = req
    ..status = req.status;
    try{
      resp
        ..respObj = JSON.decode(req.responseText)
        ..success = resp.respObj['success']
        ..msg = ServerMsg.transform(resp.respObj['msg']);
    }catch(e){
      LOG.warning("error parsing response to JSON +\n"+req.responseText);
      resp.respObj = req.responseText;
      resp.success == false; //TODO REALLY?
    }
    return resp;
  }

  /// process request, never completes error -> in this case, response has success false (or status !=200)
  Future<HttpResp> send2(String url,{String method:'GET', dynamic data, String token}){
    Completer<HttpResp> completer = new Completer<HttpResp>();
      LOG.fine('${method==null?'GET':method}:$url');
      if(data!=null ) LOG.finest('    DATA: $data');
      request(url, withCredentials: true, method: method, sendData: data, token: token/*, responseType:'json'*/).then((HttpRequest req) {  // callback function
        LOG.fine("RESPONSE: ${req.responseText}");
        completer.complete(_createResponse(req));
      }, onError: ( HttpRequest req){
        LOG.severe("ERROR RESPONSE: ${req.status} ${req.responseText}");
        var resp = _createResponse(req);
        resp.success = false;
        if(req.status == 0){
          ctx.offlineMode = true;
        }
        completer.complete(resp);
      });
    return completer.future;
  }


  /// wrap [send2] with logic: if error 401 -> try to login first with token.
  Future<HttpResp> send2Token(String url,{String method:'GET', dynamic data}){
    return ctx.storage.getSett().then((sett){

      return send2(url, method: method, data:data, token: sett.token).then((HttpResp resp){
        if(resp.status == 401){
            if(sett.token!=null && sett.token.isNotEmpty){
              return loginWithToken(sett.token).then((HttpResp loginResp){
                if(loginResp!=null && loginResp.success ){
                  return ctx.storage.settAction((sett){
                      sett.offline = false;
                    }).then((sett){
                      ctx.offlineMode = false;
                      if(url.contains("/api/user/me") || url.contains("/api/account/get")){
                        return send2(url, method:method, data:data);
                      }else{
                        return ctx.initialization.initServerUser().then((_){
                          return send2(url, method:method, data:data);
                        });
                      }
                    });
                }else{
                  return resp;
                }
              });
            }else{
              return resp;
            }
        }else{
          return resp;
        }
      });
    });
  }

  Future<HttpRequest> request(String url,
      {String method, bool withCredentials, String responseType,
      String mimeType, Map<String, String> requestHeaders, sendData,
      void onProgress(ProgressEvent e), String token}) {
    var completer = new Completer<HttpRequest>();

//    if(token!=null){
//      if(url.contains("?")){
//        url +="&token=$token";
//      }else{
//        url +="?token=$token";
//      }
//    }

    var xhr = new HttpRequest();
    if (method == null) {
      method = 'GET';
    }
    xhr.open(method, url, async: true);

    if (withCredentials != null) {
      xhr.withCredentials = withCredentials;
    }

    if (responseType != null) {
      xhr.responseType = responseType;
    }

    if (mimeType != null) {
      xhr.overrideMimeType(mimeType);
    }
    if(token!=null){
      xhr.setRequestHeader("Token", token);
    }


    if (requestHeaders != null) {
      requestHeaders.forEach((header, value) {
        xhr.setRequestHeader(header, value);
      });
    }

    if (onProgress != null) {
      xhr.onProgress.listen(onProgress);
    }

    xhr.onLoad.listen((e) {
      // Note: file:// URIs have status of 0.
      if ((xhr.status >= 200 && xhr.status < 300) ||
          xhr.status == 0 || xhr.status == 304) {
        completer.complete(xhr);
      }else {
        completer.completeError(xhr);
      }
    });

    xhr.onError.listen((e) {
      completer.completeError(xhr);
    });

    if (sendData != null) {
      xhr.send(sendData);
    } else {
      xhr.send();
    }

    return completer.future;
  }


}