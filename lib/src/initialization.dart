part of itinnutil;


class Initialization{

  ItinnUtilContext ctx;
  Logger LOG;

  Initialization():super(){
    ctx = ItinnUtilContext.instance;
    LOG = ctx.LOG;
  }



  Future initSettings(){
    return ctx.storage.getSett(ctx:ctx).then((sett){
       ctx.moreAnim = sett.moreAnimations;
       ctx.offlineMode = sett.offline;
    });
  }
  ///set server mode and initialize server user and server data
  Future<InitServerStatus> initServer(){
    LOG.finest('Init server starting. ServerMode:${ctx.serverMode}');
    return ctx.storage.getSett().then((sett){
      ctx.serverMode = (sett.me!=null && sett.me.LoginID!=null) || sett.token!=null;
      if(ctx.serverMode){
        LOG.finest('starting initialization of server. ServerMode:${ctx.serverMode}');
        //init server side
        return initServerUser().then((status){
          if(status==InitServerStatus.OK){
            return initServerData().then((ok){
              if(ok){
                return status;
              }else{
                return InitServerStatus.ERR;
              }
            });
          }else{
            return status;
          }
        });
      }else{
        LOG.finest('skipping initialization of server. ServerMode:${ctx.serverMode}');
        return InitServerStatus.OFFLINE;
      }
    });
  }

  ///main initialization
  Future<bool> init(){
    LOG.info('Common initialization started');
      var c = new Completer<bool>();

      LOG.finest('init settings');
      ctx.perfLog("init settings start");
      initSettings().then((_){
        ctx.perfLog("init settings done");
        LOG.finest('init settings DONE');
        LOG.finest('init serverside');
        ctx.perfLog("init server start");
        return initServer();
      }).then((InitServerStatus status){
        LOG.finest('init serverside DONE! status: ${status.value}');
        ctx.perfLog("init server done ");
        c.complete(true);
        LOG.info('Initialization completed successfully');
      });
      return c.future;
  }




//  ///sync me and set following settings
//  Future<bool> syncMe(){
//    var c = new Completer<bool>();
//    ctx.server.common.syncMe().then((UserDO meDO){
//      if(!ctx.offlineMode){
//        if(meDO!=null && meDO.Id !=null){
//          ctx.serverMode = true;
//          c.complete(true);
//        }else{
//          c.complete(false);
////          app.data.settAction((sett){
////            sett.me = null;
////          }).then((_){
////            c.complete(false);
////          });
//        }
//      }else{
//        c.complete(false);
//      }
//    });
//    return c.future;
//  }
  ///sync all data
  Future<bool> syncData({bool processErrors : true}){
    var c = new Completer<bool>();
    ctx.server.sync(processErrors:processErrors).then((resp){
      if(resp.success){
        ctx.mask.mask(maskIcon: MaskIcon.INFO, text: 'Done!');
        c.complete(true);
      }else if(resp.recoverySuccess){
        ctx.mask.mask(maskIcon: MaskIcon.INFO, mode:MaskMode.OK, text: 'Check your changes, please!').then((_){
          c.complete(true);
        });
      }else{
        ctx.mask.mask(maskIcon: MaskIcon.ERROR, mode:MaskMode.OK ,text: 'Error while saving!').then((_){
          c.complete(true);
        });
      }
      LOG.finest('Checking save after sync success: $resp');
      ctx.storage.checkSave(deep:true);
    });

    return c.future;

    //return server.sync(processErrors);
  }

  Future<bool> initServerData(){
    var c = new Completer<bool>();
    //app.roles.updateRolesClass(); TODO roles
    ctx.storage.storeSett.getSett().then((sett){
      if(sett.lastProfileId!=null && sett.lastProfileId!=sett.profile.Id){
        //Delete all data
        ctx.storage.clearAll().then((_){
          LOG.finest('All data cleared! Profile changed.');

          //sync data
          syncData().then((bool ok){
            LOG.finest('All data synced: Result: $ok');
            c.complete(ok);
          });
        });
      }else{
        //sync data
        syncData().then((bool ok){
          LOG.finest('All data synced: Result: $ok');
          c.complete(ok);
        });
      }
    });
    return c.future;
  }

  ///initialize server side -> sync ME and get server status (offline, 401)
  Future<InitServerStatus> initServerUser(){
    var c = new Completer<InitServerStatus>();
    ctx.storage.storeSett.getSett().then((sett){
      var loginId = "";
      if(sett.me!=null){
        loginId = sett.me.LoginID;
      }

      if(!ctx.offlineMode){
        ctx.server.common.syncMe().then((meDO){
          var ok = meDO!=null && meDO.Id !=null;
          LOG.finest('Synchronization of ME Done: Result: $ok');
          if(ok){
            c.complete(InitServerStatus.OK);
          }else{
            if(ctx.offlineMode){//changed to offline
              LOG.finest('ERR because of offline mode');
              c.complete(InitServerStatus.OFFLINE);
            }else{//probably 401
              LOG.finest('ERR because of 401');
              c.complete(InitServerStatus.E401);
            }
          }
        });

      }else{
        LOG.finest('skipping initialization of server. OFFLINE:${ctx.offlineMode}');
        c.complete(InitServerStatus.OFFLINE);
      }
    });
    return c.future;
  }




}

class InitServerStatus{
  static const E401 = const InitServerStatus._("e401");
  static const OK = const InitServerStatus._("ok");
  static const ERR = const InitServerStatus._("err");
  static const OFFLINE = const InitServerStatus._("off");
  final String value;
  const InitServerStatus._(this.value);
}
