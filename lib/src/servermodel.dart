part of itinnutil;

class UsersServer extends SyncServer{

  UsersServer():super(){
    store = ctx.storage.storeUser;
    syncUrl = ctx.SERVER +"/api/user/sync";
  }

  UserDO fromJsonMap(Map userMap){
    return UserDO.fromJsonMap(userMap);
  }
}


//class DevIssuesServer extends MultiSyncServer{
//  DevIssuesServer(String appid):super(){
//    stores = {"Issue":ctx.storage.storeDevIssue};
//    syncUrl = ctx.SERVER +"/api/issue/sync?appid=$appid";
//  }
//
//  GeneralDO fromJsonMap(Map map, String prefix){
//    if(prefix=="Issue"){
//      return DevIssueDO.fromJsonMap(map);
//    }else{
//      LOG.severe('!!!Error: Wrong prefix while getting DO from MAP. prefix: $prefix');
//      return null;
//    }
//  }
//}
