part of itinnutil;


class AccountManager{

  ItinnUtilContext get ctx => ItinnUtilContext.instance;

  Future<bool> createUser( String userid, String password1, String password2){
      if(password1!=password2){
        ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: "Passwords not equal!", mode: MaskMode.OK);
        return new Future.value(false);
      }else{
        var c = new Completer<bool>();
        ctx.mask.mask(text: "Creating user and logging in...");
        ctx.server.common.createAccount(userid, password1).then((HttpResp resp){
          if(resp!=null && resp.success){
            ctx.storage.settAction((sett){
              sett.offline = false;
              sett.me = UserDO.fromJsonMap(resp.respObj['Data']);
              sett.token = resp.respObj['Data']['Token'];
            }).then((sett){
              ctx.offlineMode = sett.offline;
              ctx.initialization.initServer().then((_){
                ctx..mask.umMaskDefer();
                c.complete(true);
                ctx.bus.fire(EventBus.EV_LOGIN, true);
              });
            });

          }else{
            ctx.storage.settAction((sett){
              sett.offline = true;
            }).then((sett){
              ctx.offlineMode = sett.offline;
              if(resp!=null && resp.msg!=null){
                ctx.mask.maskWithMsg(resp.msg);
              }else{
                ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: "Unable to create user!", mode: MaskMode.OK);
              }
              c.complete(false);
              ctx.bus.fire(EventBus.EV_LOGIN, false);
            });
          }
        });
        return c.future;
      }


  }
  ///login user
  Future<bool> login( String userid, String password){
    var c = new Completer<bool>();
      ctx.mask.mask(text: "Logging in...");
      ctx.server.common.login(userid, password).then((HttpResp resp){
        if(resp!=null && resp.success){
          ctx.storage.settAction((sett){
            sett.offline = false;
            sett.me = UserDO.fromJsonMap(resp.respObj['Data']);
            sett.token = resp.respObj['Data']['Token'];
          }).then((sett){
            ctx.offlineMode = sett.offline;
            ctx.initialization.initServer().then((_){
              ctx..mask.umMaskDefer();
              c.complete(true);
              ctx.bus.fire(EventBus.EV_LOGIN, true);
            });
          });

        }else{
          ctx.storage.settAction((sett){
            sett.offline = true;
          }).then((sett){
            ctx.offlineMode = sett.offline;
            if(resp!=null && resp.msg!=null){
              ctx.mask.maskWithMsg(resp.msg);
            }else{
              ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: "Unable to log in!", mode: MaskMode.OK);
            }
            c.complete(false);
            ctx.bus.fire(EventBus.EV_LOGIN, false);
          });
        }
      });
    return c.future;
  }
  ///logout user
  Future<bool> maskLogout(){
    var c = new Completer<bool>();
    var _logout = (){
      ctx.mask.mask(text: 'Logging out...');
      logout().then((ok){
        if(ok){
          ctx.mask.mask(maskIcon: MaskIcon.INFO, text: 'Done!');
          ctx.mask.unMaskDeferNoBtt();
        }else{
          ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: 'Sorry, unable to logout!',  mode: MaskMode.OK);
        }
        c.complete(ok);
      });
    };

    ctx.mask.mask(maskIcon: MaskIcon.QUESTION, text: 'Logout?' , mode: MaskMode.YESNO).then((resp){
        if(resp==MaskComplete.YES){
          ctx.storage.isSync(deep:true).then((synced){
            if(synced){
              _logout();
            }else{
              ctx.mask.mask(maskIcon: MaskIcon.QUESTION, text: 'Save data to server before logout?' , mode: MaskMode.YESNO).then((resp){
                if(resp==MaskComplete.YES){
                  ctx.initialization.syncData().then((ok){
                    if(ok){
                      _logout();
                    }else{
                      ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: 'Sorry, unable to save data!' , mode: MaskMode.OK);
                      c.complete(false);
                    }
                  });
                }else{
                  _logout();
                }
              });
            }
          });
        }else{
          c.complete(false);
        }
      });
    return c.future;
  }
  ///call server logout and clean user data
  Future<bool> logout(){
      return ctx.server.common.logout().then((HttpResp resp){
        if(resp.success){
          return ctx.storage.settAction((sett){
            sett.me = null;
            sett.profile = null;
            sett.offline = true;
            sett.token = null;
            ctx.serverMode = false;
            ctx.offlineMode = true;
          }).then((sett){
            ctx.bus.fire(EventBus.EV_LOGOUT, true);
            return true;
          });
        }else{
          ctx.bus.fire(EventBus.EV_LOGOUT, false);
          return false;
        }
      });
  }

}
