part of itinnutil;

class HttpResp{
  HttpRequest request;
  int status;
  bool success;
  List<ServerMsg> msg;
  var respObj;
}
class ServerMsg extends MaskMsg{

  ServerMsg(Code, Type, DefTxt): super(Code, Type, DefTxt);

  ServerMsg.fromJsonMap(Map jsonMap):super.fromJsonMap(jsonMap);
  static List<ServerMsg> transform(var jsonList){
    return MaskMsg.transform(jsonList);
  }
}

class CommonServer extends Server{


  CommonServer():super();

  ///create new accout for user
  Future<HttpResp> createAccount(String userid, String password){
    var url = ctx.SERVER +"/api/account/create?userid=${userid}&password=${password}";
    return send2Token(url);
  }
  ///create profile account
  Future<HttpResp> createProfileAccount(String userid, String password, [List<String> roles, String name] ){
    var url = ctx.SERVER +"/api/account/createinprofile?userid=${userid}&password=${password}";
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
    var url = ctx.SERVER +"/api/user/remove?id=${userid}";
    return send2Token(url);
  }
  ///login user
  Future<HttpResp> login(String userid, String password){
    var url = ctx.SERVER +"/api/account/login?userid=${userid}&password=${password}";
    return send2(url);
  }
  ///logout user
  Future<HttpResp> logout(){
    var url = ctx.SERVER +"/api/account/logout";
    return send2Token(url);
  }

  ///get information about current logged user
  Future<HttpResp> userMe(){
    var url = ctx.SERVER +"/api/user/me";
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
          sett.me = me;
          sett.profile = profile;
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
    Map meM = resp.respObj['Data'];
    if(meM!=null && meM.isNotEmpty){
      me = UserDO.fromJsonMap(meM, me);
    }
    return me==null? new UserDO():me;
  }
  static ProfileDO _saveProfile(HttpResp resp, [ProfileDO profile]){
    Map map = resp.respObj['Profile'];
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


//  Future<HttpResp> send(String url,[String method, data, bool ignore401=false, bool ignoreToken=false]){
//    Completer<HttpResp> completer = new Completer<HttpResp>();
//
//      LOG.fine('${method==null?'GET':method}:$url');
//      if(data!=null ) LOG.finest('    DATA: $data');
//      request(url, withCredentials: true, method: method, sendData: data/*, responseType:'json'*/).then((HttpRequest req) {  // callback function
//        LOG.fine("RESPONSE: ${req.responseText}");
//        HttpResp resp = new HttpResp();
//        resp
//          ..request = req
//          ..status = req.status
//          ..respObj = JSON.decode(req.responseText)
//          ..success = resp.respObj['Success']
//          ..msg = ServerMsg.transform(resp.respObj['Msg']);
//  //      resp.msg = ServerMsg.transform(resp.respObj['Msg']);
//        completer.complete(resp);
//
//      }, onError: ( HttpRequest req){
//        LOG.severe("ERROR RESPONSE: ${req.status} ${req.responseText}");
//        ctx.storage.getSett().then((sett){
//          if(req.status==401 && !ignoreToken && sett.me!=null && sett.me.Token!=null && sett.me.Token.isNotEmpty){
//            loginWithToken(sett.me.Token, ignore401).then((HttpResp loginResp){
//              if(loginResp!=null && loginResp.success ){
//                ctx.storage.settAction((sett){
//                  sett.offline = false;
//                }).then((sett){
//                  ctx.offlineMode = sett.offline;
//                  ctx.initialization.initServerSide2().then((_){
//                    ctx.mask.umMaskDefer();
//                  });
//                });
//              }else{
//
//              }
//            });
//          }else if(!ignore401 && req.status==401){
//            //TODO login in mask
//            print('TODO - login in mask');
//            //        var lf = new LoginForm.create(false)
//            //        ..onLogin.first.then((ok){
//            //          if(ok){
//            //            send(url, method, data, true).then((resp){
//            //              completer.complete(resp);
//            //            });
//            //          }else{
//            //            completer.complete(null);
//            //          }
//            //        });
//            //        lf.loginBttRow.hide(true);
//            //        app.mask.mask(maskIcon: MaskIcon.WARN, mode:MaskMode.OKCANCEL, cmp: lf).then((status){
//            //          if(MaskComplete.OK==status){
//            //            lf.login(false);
//            //          }else{
//            //            completer.complete(null);
//            //          }
//            //        });
//          }else if(req.status==401){
//            ctx.server401 = true;
//            ctx.mask.mask(maskIcon: MaskIcon.WARN, text:'User not authorized! Try to login in settings -> account.', mode:MaskMode.OK).then((status){
//              completer.complete(null);
//            });
//
//          }else if(req.status==0){
//            ctx.offlineMode = true;
//            ctx.mask.mask(maskIcon: MaskIcon.WARN, text:'Server unreachable, going to OFFLINE mode.', mode:MaskMode.OK).then((status){
//              completer.complete(null);
//            });
//          }else{
//            if(ctx.server401) ctx.server401 = false;
//            var respObj;
//            try{
//              respObj = JSON.decode(req.responseText);
//            }catch(e){
//              respObj = req.responseText;
//            }
//            HttpResp resp = new HttpResp()
//            ..request = req
//            ..status = req.status
//            ..respObj = respObj
//            ..success = false;
//            completer.complete(resp);
//          }
//        });
//
//      });
//
//    return completer.future;
//  }
  HttpResp _createResponse(HttpRequest req){
    HttpResp resp = new HttpResp();
    resp
    ..request = req
    ..status = req.status;
    try{
      resp
        ..respObj = JSON.decode(req.responseText)
        ..success = resp.respObj['Success']
        ..msg = ServerMsg.transform(resp.respObj['Msg']);
    }catch(e){
      resp.respObj = req.responseText;
      resp.success == false; //TODO REALLY?
    }
    return resp;
  }

  /// process request, never completes error -> in this case, response has success false (or status !=200)
  Future<HttpResp> send2(String url,{String method:'GET', dynamic data}){
    Completer<HttpResp> completer = new Completer<HttpResp>();
      LOG.fine('${method==null?'GET':method}:$url');
      if(data!=null ) LOG.finest('    DATA: $data');
      request(url, withCredentials: true, method: method, sendData: data/*, responseType:'json'*/).then((HttpRequest req) {  // callback function
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
    return send2(url, method: method, data:data).then((HttpResp resp){
      if(resp.status == 401){
        return ctx.storage.getSett().then((sett){
          if(sett.token!=null && sett.token.isNotEmpty){
            return loginWithToken(sett.token).then((HttpResp loginResp){
              if(loginResp!=null && loginResp.success ){
                return ctx.storage.settAction((sett){
                    sett.offline = false;
                  }).then((sett){
                    ctx.offlineMode = false;
                    if(url.contains("/api/user/me")){
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
        });
      }else{
        return resp;
      }
    });
  }

  Future<HttpRequest> request(String url,
      {String method, bool withCredentials, String responseType,
      String mimeType, Map<String, String> requestHeaders, sendData,
      void onProgress(ProgressEvent e)}) {
    var completer = new Completer<HttpRequest>();

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