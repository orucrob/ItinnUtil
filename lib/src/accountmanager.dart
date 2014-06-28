part of itinnutil;


class AccountManager{

  ItinnUtilContext get ctx => ItinnUtilContext.instance;

  Future<bool> createUser( String userid, String password1, String password2){
      if(password1!=password2){
        ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.password.err1"], mode: MaskMode.OK);
        return new Future.value(false);
      }else{
        var c = new Completer<bool>();
        ctx.mask.mask(text: ctx.i18n["iu.am.signup.progress"]);
        ctx.server.common.createAccount(userid, password1).then((HttpResp resp){
          if(resp!=null && resp.success){
            ctx.storage.settAction((sett){
              sett.offline = false;
              sett.me = UserDO.fromJsonMap(resp.respObj['user']);
              sett.token = resp.respObj['token'];
            }).then((sett){
              ctx.offlineMode = sett.offline;
              ctx.initialization.initServer().then((_){
                ctx..mask.unMaskDefer();
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
                ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.signup.failed"], mode: MaskMode.OK);
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
      ctx.mask.mask(text: ctx.i18n["iu.am.signin.progress"]);
      ctx.server.common.login(userid, password).then((HttpResp resp){
        if(resp!=null && resp.success){
          ctx.storage.settAction((sett){
            sett.offline = false;
            sett.me = UserDO.fromJsonMap(resp.respObj['user']);
            sett.token = resp.respObj['token'];
          }).then((sett){
            ctx.offlineMode = sett.offline;
            ctx.initialization.initServer().then((_){
              ctx..mask.unMaskDefer();
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
              ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.signin.failed"], mode: MaskMode.OK);
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
      ctx.mask.mask(text: ctx.i18n["iu.am.signout.progress"]);
      logout().then((ok){
        if(ok){
          ctx.mask.mask(maskIcon: MaskIcon.INFO, text: ctx.i18n["iu.am.signout.done"]);
          ctx.mask.unMaskDeferNoBtt();
        }else{
          ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.signout.failed"],  mode: MaskMode.OK);
        }
        c.complete(ok);
      });
    };

    ctx.mask.mask(maskIcon: MaskIcon.QUESTION, text: ctx.i18n["iu.am.signout.q"] , mode: MaskMode.YESNO).then((resp){
        if(resp==MaskComplete.YES){
          ctx.storage.isSync(deep:true).then((synced){
            if(synced){
              _logout();
            }else{
              ctx.mask.mask(maskIcon: MaskIcon.QUESTION, text: ctx.i18n["iu.am.signout.q2"] , mode: MaskMode.YESNO).then((resp){
                if(resp==MaskComplete.YES){
                  ctx.initialization.syncData().then((ok){
                    if(ok){
                      _logout();
                    }else{
                      ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.signout.failed2"] , mode: MaskMode.OK);
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
    //TODO no server logout?
//      return ctx.server.common.logout().then((HttpResp resp){
//        if(resp.success){
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
//        }else{
//          ctx.bus.fire(EventBus.EV_LOGOUT, false);
//          return false;
//        }
//      });
  }

  //create profile user
  Future<bool> createProfileUser( String userid, String password1, String password2){
      if(password1!=password2){
        ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.password.err1"], mode: MaskMode.OK);
        return new Future.value(false);
      }else{
        var c = new Completer<bool>();
        ctx.mask.mask(text: ctx.i18n["iu.am.signup.progress"]);
        ctx.server.common.createProfileAccount(userid, password1).then((HttpResp resp){
          if(resp!=null && resp.success){
            ctx.mask.mask(maskIcon: MaskIcon.INFO, text: ctx.i18n["iu.am.signup.done"], unMaskDefer: true);
            c.complete(true);
          }else{
            if(resp!=null && resp.msg!=null){
              ctx.mask.maskWithMsg(resp.msg);
            }else{
              ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.signup.failed"], mode: MaskMode.OK);
            }
            c.complete(false);
          }
        });
        return c.future;
      }
  }

  ///remove user from profile
  Future<bool> removeProfileUser( String userid){
    var c = new Completer<bool>();
    ctx.mask.mask(maskIcon: MaskIcon.QUESTION, text: ctx.i18n["iu.am.removeprofileuser.q"] , mode: MaskMode.YESNO).then((resp){
        if(resp==MaskComplete.YES){
          ctx.mask.mask(text: ctx.i18n["iu.am.removeprofileuser.progress"]);
          ctx.server.common.removeUserFromProfile(userid).then((HttpResp resp){
            if(resp!=null && resp.success){
              ctx.mask.mask(maskIcon: MaskIcon.INFO, text: ctx.i18n["iu.am.removeprofileuser.done"], unMaskDefer: true);
              c.complete(true);
            }else{
              if(resp!=null && resp.msg!=null){
                ctx.mask.maskWithMsg(resp.msg);
              }else{
                ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.removeprofileuser.failed"], mode: MaskMode.OK);
              }
              c.complete(false);
            }
          });
        }else{
          c.complete(false);
        }
      });

    return c.future;

  }

  ///change user roles
  Future<bool> changeUserRoles(String userid, List<String> roles){
    var c = new Completer<bool>();
    ctx.mask.mask(text: ctx.i18n["iu.am.changeroles.progress"]);
    ctx.server.common.setUserRoles(userid, roles).then((resp){
      if(resp!=null && resp.success){
        ctx.mask.mask(maskIcon: MaskIcon.INFO, text: ctx.i18n["iu.am.changeroles.done"], unMaskDefer: true);
        ctx.bus.fire(EventBus.EV_ROLECHANGED, {"user":userid, "roles":roles});
        c.complete(true);
      }else{
        if(resp!=null && resp.msg!=null){
          ctx.mask.maskWithMsg(resp.msg);
        }else{
          ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: ctx.i18n["iu.am.changeroles.failed"], mode: MaskMode.OK);
        }
        c.complete(false);
      }
    });

    return c.future;

  }


}
