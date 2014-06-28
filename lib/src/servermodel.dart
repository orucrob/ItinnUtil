part of itinnutil;

class UsersServer extends MultiSyncServer{

  UsersServer():super(){
    stores = {"user":ctx.storage.storeUser};
    syncUrl = ctx.SERVER +"/api/user/sync";
  }

  UserDO fromJsonMap(Map userMap, String prefix){
    if(prefix=="user"){
      return UserDO.fromJsonMap(userMap);
    }else{
      LOG.severe('!!!Error: Wrong prefix while getting DO from MAP in UsersServer. prefix: $prefix');
      return null;
    }
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
