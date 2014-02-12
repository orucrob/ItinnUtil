part of itinnutil;

class ServerCtrl {
  CommonServer common;
  UsersServer users;
//  DevIssuesServer devIssues;
  ServerCtrl(String appid){
    common = new CommonServer();
    users = new UsersServer();
 //   devIssues = new DevIssuesServer(appid);
  }
  Future<OperationResponse> sync({bool processErrors : true}){
    //return users.sync(processErrors: processErrors);
    var c = new Completer<OperationResponse>();
    var success = true;
    var offline = false;
    var errors = new List();
    users.sync(processErrors: processErrors).then((resp){
      if(!resp.success) {
        success = false;
        if(resp.errors!=null) errors.addAll(resp.errors);
      }
      if(resp.offline){
        offline = true;
      }
//      devIssues.sync(processErrors: processErrors)..then((resp){
//        if(!resp.success) {
//          success = false;
//          if(resp.errors!=null) errors.addAll(resp.errors);
//        }
        var allResp = new OperationResponse()..offline = offline..success = success .. errors = errors;
        c.complete(allResp);
//      });
    });
    return c.future;
  }


  Future<OperationResponse> recovery({bool processErrors : false}){
    //return users.recovery(processErrors: processErrors);
    var c = new Completer<OperationResponse>();
    var success = true;
    var offline = false;
    var errors = new List();
    users.recovery(processErrors: processErrors).then((resp){
      if(!resp.success) {
        success = false;
        if(resp.offline){
          offline = true;
        }
        if(resp.errors!=null) errors.addAll(resp.errors);
      }
//      devIssues.recovery(processErrors: processErrors)..then((resp){
//        if(!resp.success) {
//          success = false;
//          if(resp.errors!=null) errors.addAll(resp.errors);
//        }
        var allResp = new OperationResponse()..offline = offline..success = success .. errors = errors;
        c.complete(allResp);
//      });
    });
    return c.future;
  }

}
