part of itinnutil;
class SyncReqData{
  List create;
  List update;
  List delete;
  int version;
  SyncReqData(){
  }
  Map toJsonMap(){
    var createMap, updateMap, deleteMap;
    if(this.create!=null && this.create.isNotEmpty){
      createMap = new List();
      this.create.forEach((item){
        createMap.add(item.toJsonMap());
      });
    }
    if(this.update!=null && this.update.isNotEmpty){
      updateMap = new List();
      this.update.forEach((item){
        updateMap.add(item.toJsonMap());
      });
    }
    if(this.delete!=null && this.delete.isNotEmpty){
      deleteMap = new List();
      this.delete.forEach((item){
        deleteMap.add(item.toJsonMap());
      });
    }
    return {
      'create': createMap,
      'update': updateMap,
      'delete': deleteMap,
      'version':this.version
    };
  }
  String toJson(){
    return JSON.encode(toJsonMap());
    //return stringify(toJsonMap());
  }
}
class MultiSyncReqData{
  Map<String,List> create;
  Map<String,List> update;
  Map<String,List> delete;
  Map<String,int> version;
  MultiSyncReqData(){
  }
  Map toJsonMap(){
    var createMap, updateMap, deleteMap;
    var retMap = {};
    if(this.create!=null && this.create.isNotEmpty){
      this.create.forEach((prefix, list){
        createMap = new List();
        list.forEach((item){
          createMap.add(item.toJsonMap());
        });
        retMap['${prefix}Create'] = createMap;
      });
    }
    if(this.update!=null && this.update.isNotEmpty){
      this.update.forEach((prefix, list){
        updateMap = new List();
        list.forEach((item){
          updateMap.add(item.toJsonMap());
        });
        retMap['${prefix}Update'] = updateMap;
      });
    }
    if(this.delete!=null && this.delete.isNotEmpty){
      this.delete.forEach((prefix, list){
        deleteMap = new List();
        list.forEach((item){
          deleteMap.add(item.toJsonMap());
        });
        retMap['${prefix}Delete'] = deleteMap;
      });
    }
    if(this.version!=null && this.version.isNotEmpty){
      this.version.forEach((prefix, version){
        retMap['${prefix}Version'] = version;
      });
    }
    return retMap;
  }
  String toJson(){
    return JSON.encode(toJsonMap());
    //return stringify(toJsonMap());
  }
}

class ErrorSyncDesc{
  Map serverItem;
  GeneralDO localItem;
  String errorStatus;
}

class OperationResponse{
  bool offline = false;
  bool success = true;
  bool recoverySuccess = false;
  List<ErrorSyncDesc> errors;
  List<ErrorSyncDesc> recoveryErrors;
}

/**
 * SYNC MULTI STORE
 */
abstract class MultiSyncServer extends Server{

  Stream<OperationResponse> onSync;
  StreamController<OperationResponse> _syncCtrl;

  Map<String, SyncStorage> stores;
  GeneralDO fromJsonMap(Map jsonMap, String prefix);
  String syncUrl;

  MultiSyncServer({this.stores, this.syncUrl}):super(){
    _syncCtrl = new StreamController();
    onSync = _syncCtrl.stream.asBroadcastStream();
  }

   ///MAIN sync process
  Future<OperationResponse> sync({bool processErrors : true, bool partOfRecovery: false}){
    var c = new Completer<OperationResponse>();

    var versions = new Map<String, int>();
    var toSave = new Map<String, List<GeneralDO>>();
    var resp, opResp;
    var prefixes = new List();

    var ctx = ItinnUtilContext.instance;


    Future f = new Future.value();

    if(ctx!=null) ctx.status("Preparing data to send.");
    //GET VERSION
    stores.forEach((prefix,store){
      f = f.then((_){
        return store.getVersion(deep: true).then((version){
          versions[prefix] = version;
          prefixes.add(prefix);
        });
      });
    });
    //PREPARE DATA
    f = f.then((_){
      return prepareSyncData().then((val){
        toSave = val;
      });
    });
    //SYNC
    f = f.then((_){
      if(ctx!=null) ctx.status("Sending data.");
      return _sync(syncUrl, toSave, versions).then((r){
        resp = r;
      });
    });
    //PROCESS response
    f = f.then((_){
      if(ctx!=null) ctx.status("Received response.");
      return processResponse(resp, prefixes, toSave, processErrors, recovery:partOfRecovery).then((r){
        opResp = r;
      });
    });

    //end
    f.then((_){
      if(ctx!=null) ctx.status("Response processed.");

      c.complete(opResp);
      _syncCtrl.add(opResp);
    });


    return c.future;
  }
  /**
   * Process changed items as OK, without errors
   */
  Future<OperationResponse> processSuccess(List changed, List<String> allIDs, newVersion,  String prefix, [OperationResponse response, bool processErrors=false, bool skipVersion=false]){
    var c = new Completer();
    Future f = new Future.value();

    //ignore status, because changed should be all OK
    //CHANGED
    f = f.then((_){
      return _processChanges(changed, prefix);
    });

    //AllIDs
    if(allIDs!=null){ //TODO overit, ze ked je uplna chyba, tak allIDS je null, ked je empty, tak to znamena, ze je OK, ale user nema data

      //add IDs that were not successfully synchronized (prevent deletion)
      if(response!=null && response.errors!=null){
        response.errors.forEach((err){
          if(!allIDs.contains(err.localItem.Id)){
            allIDs.add(err.localItem.Id);
          }
        });
      }
      f = f.then((_){
        return _processAllIDS(allIDs, prefix);
      });
    }
    //process errors
    if(processErrors){
      f = f.then((_){
        return processSyncErrors(response).then((recoveryResp){
          response = recoveryResp;
        });
      });
    }

    //FINAL clean
    f = f.then((_){
      stores[prefix].isSync(deep: true);
      if(!skipVersion){
        stores[prefix].version = int.parse("$newVersion", radix:10);
      }
    });

    //end
    f.then((_){
      c.complete(response);

    });
    return c.future;
  }

  ///MAIN process response method
  Future<OperationResponse> processResponse(resp, List<String> prefixes, Map<String, List<GeneralDO>> toSave, bool processErrors, {bool recovery:false}){
    var c = new Completer<OperationResponse>();
    if(resp==null || resp.respObj==null || resp.respObj is String || resp.status==0){
      var response = new OperationResponse();
      response.offline = resp.status==0;
      response.success = false;
      c.complete(response);
    }else{
      var response = new OperationResponse();
      List<String> batchSignal = new List();
      response.success = resp.success;
      Future f = new Future.value();
      //batch signal
      if(!recovery){
        prefixes.forEach((prefix){
          var changed = resp.respObj['${prefix}Changed'];
          //batch signal
          if(changed!=null && changed.length>10){
            batchSignal.add(prefix);
            stores[prefix].batchStartCtrl.add(true);
          }
        });
      }

      prefixes.forEach((prefix){
        //CHANGED
        var changed = resp.respObj['${prefix}Changed'];
        var allIDs = resp.respObj['${prefix}AllIDs'];
        var newVersion = resp.respObj['${prefix}Version'];
        var statusMap = resp.respObj['${prefix}Status'];

        // SUCCESS
        if(resp.success){
          f = f.then((_){
            return processSuccess(changed, allIDs, newVersion, prefix);
          });

        // FAIL
        }else{
          //prepare error and remove errors from changed
          if(response.errors==null){
            response.errors = new List();
          }
          if(toSave!=null && toSave[prefix]!=null){
            toSave[prefix].forEach((item){
              if(statusMap!=null && statusMap[item.SyncId]!=null && statusMap[item.SyncId].startsWith('E')){
                //ERROR
                var err = new ErrorSyncDesc();
                err.errorStatus = statusMap[item.SyncId];
                err.localItem = item;
                response.errors.add(err);
                if(changed!=null){
                  var found;
                  changed.forEach((itemMap){
                    if(item.Id == itemMap['Id'] || item.SyncId == itemMap['SyncId']){
                      err.serverItem = itemMap;
                      found = itemMap;
                    }
                  });
                  if(found!=null){
                    changed.remove(found);
                  }
                }                }
            });
          }
          //rest of changed process as success
          f = f.then((_){
            return processSuccess(changed, allIDs, newVersion, prefix, response, processErrors, true).then((resp){
              response = resp;
            });
          });

        }//END FAIL

      });//END PREFIXES
      f.then((_){
        c.complete(response);
        //batch signal
        batchSignal.forEach((prefix){
          stores[prefix].batchStartCtrl.add(true);
        });
        //sync stream
        _syncCtrl.add(response); //CTRL!!!!!
      });
    }//END resp is not null
    return c.future;
  }


  Future<OperationResponse> processSyncErrors(OperationResponse resp){
    var c = new Completer<OperationResponse>();
    if(resp!=null && !resp.success && resp.errors!=null && resp.errors.isNotEmpty){
      var conflict = 0;
      var na = 0;
      var general = 0;
      resp.errors.forEach((err){
        if(err.errorStatus == 'EC'){
          //conflict
          conflict++;
        }else if(err.errorStatus == 'ENA'){
          //item not available
          na++;
        }else{
          general++;
        }
      });
      var errTxt = "Unable to synchronize!";
      if(conflict>0){
        errTxt += "<br>$conflict conflict${conflict==1?"":"s"} (Maybe other device changes?)";
      }
      if(na>0){
        errTxt += "<br>$na data inconsitence${na==1?"":"s"} (Ufff, sorry ;-()";
      }
      if(general>0){
        errTxt += "<br>$general not available${general==1?"":"s"} (Maybe other device deletions?)";
      }
      ctx.mask.mask(
          maskIcon: MaskIcon.ERROR,
          text:'$errTxt <br>Perform recovery? ' ,
          mode: MaskMode.YESNO).then((resp3){
        if(resp3 == MaskComplete.YES){
          //if yes
          ctx.mask.mask(text: 'Recovering data from server...');
          recovery(processErrors: false).then((OperationResponse resp2){
            if(resp2.success){
              //ok
              ctx.mask.mask(maskIcon: MaskIcon.INFO, text: 'Recovery done.');
              ctx.mask.umMaskDefer().then((_){
                resp.recoverySuccess = true;
                resp.recoveryErrors = resp2.errors;
                c.complete(resp);
              });
            }else{
              //notok
              ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: 'Recovery failed.', mode:MaskMode.OK).then((_){
                resp.recoverySuccess = false;
                resp.recoveryErrors = resp2.errors;
                c.complete(resp);
              });
            }
          });
        }else{
          resp.recoverySuccess = false;
          c.complete(resp);
        }
      });
    }
    return c.future;
  }

  ///MAIN recovery process
  Future<OperationResponse> recovery({bool processErrors : false}){
    var c = new Completer<OperationResponse>();
    Future f = new Future.value(true);
    stores.forEach((prefix, store){
      f = f.then((ok){
        if(!ok){
          return false;
        }else{
          store.batchStartCtrl.add(true);
//          store.suppressStreams = true;
          return store.clear();
        }
      });
    });
    f = f.then((ok){
      if(ok){
        return sync(processErrors:processErrors, partOfRecovery: true);
      }else{
        var resp = new OperationResponse()..success = false..recoverySuccess=false;
        return resp;
      }
    });
    f.then((resp){
      stores.forEach((prefix, store){
        store.batchEndCtrl.add(true);
//        store.suppressStreams = false;
      });
      c.complete(resp);
    });
    return c.future;
  }


  ///1. get not synchronized data
  Future<Map<String,List<GeneralDO>>> prepareSyncData(){
    var c = new Completer();
    var ret = new Map<String,List<GeneralDO>>();

    var chF = [];
    stores.forEach((prefix,store){
      var f = store.getAll(inclDeleted:true).then((items){
        //var childFutures = new List();
        var toSave = new List();
        if(items!=null && items.isNotEmpty){
          //for each child
          items.forEach((item){
            if(item.Sync != GeneralDO.SYNC_OK){
              toSave.add(item);
            }
          });
        }
        ret[prefix] = toSave;
      });
      chF.add(f);
    });
    //wait
    Future.wait(chF).then((_){
      c.complete(ret);
    });

    return c.future;
  }

  ///3.process changes from sync request
  Future _processChanges(List<Map> changed, String prefix){
    LOG.finest('SYNC - ${prefix} changes - start.');
    var c = new Completer();
    if(changed!=null){
//      if(changed.length>10){
//        //split (prevent out of memory)
//        LOG.finest('SYNC - ${prefix} changes - PARELLEL SPLIT');
//        var part = changed.sublist(0,10);
//        var rest = changed.sublist(10);
//        var c = new Completer();
//        _processChanges(part, prefix).then((_){
//          Timer.run((){//(prevent out of memory)
//            _processChanges(rest,prefix).then((_){
//              c.complete();
//            });
//          });
//        });
//        return c.future;
//      }else{
        //merge
        var childFutures = new List();

        var f = new Future.value("start");
        var all = changed.length;
        for(int i=0; i<all; i++){
          var idx = i;
          f = f.then((_){
            LOG.finest('SYNC - ${prefix} changes merging - ${idx+1} from ${all}.');
            if(ctx!=null) ctx.status("Processing record $idx / $all");
            var id;
            if(changed[idx]['SyncId']!=null){
              id = changed[idx]['SyncId'];
            }else{
              id = changed[idx]['Id'];
            }

            var c2 = new Completer();
            var serverItem = fromJsonMap(changed[idx], prefix);
            return stores[prefix].merge(item:serverItem, oldId:id);
          });

        }
        f.then((_){
          LOG.finest('SYNC - ${prefix} changes - done.');
          c.complete();
        });

//        changed.forEach((itemMap){
//          var id;
//          if(itemMap['SyncId']!=null){
//            id = itemMap['SyncId'];
//          }else{
//            id = itemMap['Id'];
//          }
//
//          var c2 = new Completer();
//          var serverItem = fromJsonMap(itemMap, prefix);
//          var f = stores[prefix].merge(item:serverItem, oldId:id);
//          childFutures.add(f);
//        });
//        Future.wait(childFutures).then((_){
//          LOG.finest('SYNC - ${prefix} changes - done.');
//          c.complete();
//        });
//      }
    }else{
      c.complete();
    }
    return c.future;
  }

  ///4. process allids from sync request
  Future _processAllIDS(List<String> allIDs, String prefix){
    LOG.finest('SYNC - ${prefix} allids - start.');
    var c = new Completer();
    stores[prefix].getAll(inclDeleted: true).then((items){
      var childFutures = new List();
      if(items!=null){
        //find all to remove
        var itemsToRemove = new List();
        items.forEach((item){
          if(!allIDs.contains(item.Id)){
            itemsToRemove.add(item);
          }else{
            allIDs.remove(item.Id);
          }
        });
        //remove if found any
        itemsToRemove.forEach((item){
          var f = stores[prefix].remove(item, sync: true);
          childFutures.add(f);
        });
        //final check
        if(allIDs.isNotEmpty){
          allIDs.forEach((id){
            LOG.finest('SYNC - ${prefix} allids - PROBLEM - ID:${id} - syncUrl: ${syncUrl}');
          });
        }
      }
      Future.wait(childFutures).then((_){
        LOG.finest('SYNC - ${prefix} allids - done.');
        c.complete();
      });
    });
    return c.future;
  }
  ///2. process sync request to server
  Future<HttpResp> _sync(String url, Map<String, List<GeneralDO>> itemsMap, Map<String, int> versions, [String method = "POST"]){
    var data = new MultiSyncReqData();
    itemsMap.forEach((prefix, List<GeneralDO> items){
      if(items!=null && items.isNotEmpty){
        items.forEach((item){
          item.SyncId = item.Id;
          //create
          if(item.Sync == GeneralDO.SYNC_CREATE){
            if(data.create == null){
              data.create = new Map<String,List>();
            }
            if(data.create[prefix]==null){
              data.create[prefix] = new List();
            }
            item.SyncId = item.Id;
            data.create[prefix].add(item);
          }
          //update
          if(item.Sync == GeneralDO.SYNC_UPDATE){
            if(data.update == null){
              data.update = new Map<String,List>();
            }
            if(data.update[prefix]==null){
              data.update[prefix] = new List();
            }
            data.update[prefix].add(item);
          }
          //delete
          if(item.Sync == GeneralDO.SYNC_DELETE){
            if(data.delete == null){
              data.delete = new Map<String,List>();
            }
            if(data.delete[prefix]==null){
              data.delete[prefix] = new List();
            }
            data.delete[prefix].add(item);
          }
        });
      }
      data.version = versions;
    });
    var json = data.toJson();
    return send2Token(url,method:method, data:json);
  }
}


/**
 * SYNC STORE
 */
abstract class SyncServer extends Server{

  Stream<OperationResponse> onSync;
  StreamController<OperationResponse> _syncCtrl;

  SyncStorage store;
  GeneralDO fromJsonMap(Map jsonMap);
  String syncUrl;

  SyncServer({this.store, this.syncUrl}):super(){
    _syncCtrl = new StreamController();
    onSync = _syncCtrl.stream.asBroadcastStream();
  }

   ///MAIN sync process
  Future<OperationResponse> sync({bool processErrors : true, bool partOfRecovery: false}){
    var c = new Completer<OperationResponse>();
    //GET VERSION
    store.getVersion(deep: true).then((version){
      //PREPARE DATA
      prepareSyncData().then((toSave){
        _sync(syncUrl, toSave, version).then((resp){
          if(resp==null || resp.respObj==null || resp.respObj is String || resp.status==0){
            var response = new OperationResponse();
            //TODO provide explanations like offline and so on..
            response.offline = resp.status==0;
            response.success = false;
            c.complete(response);
            _syncCtrl.add(response);
          }else{
            var response = new OperationResponse();
            response.success = resp.success;
            if(resp.success){
              var newVersion = resp.respObj['Version'];
              //ignore status, because response is success = everything is OK
              //CHANGED
              var changed = resp.respObj['Changed'];

              //batch signal
              bool batchSignal=false;
              if(!partOfRecovery){
                  if(changed!=null && changed.length>10){
                    batchSignal =true;
                    store.batchStartCtrl.add(true);
                  }
              }


              _processChanges(changed).then((_){
                //AllIDs
                var allIDs = resp.respObj['AllIDs'];
                _processAllIDS(allIDs).then((_){
                  //FINAL clean
                  store.isSync(deep: true);
                  store.version = int.parse("$newVersion", radix:10);
                  if(batchSignal){
                    store.batchEndCtrl.add(true);
                  }
                  c.complete(response);
                  _syncCtrl.add(response);
                });
              });
            }else{
              var newVersion = resp.respObj['Version'];
              //CHANGED
              var statusMap = resp.respObj['Status'];
              var changed = resp.respObj['Changed'];
              //proces only those with OK status
              var changedOK = new List();
              response.errors = new List();
              if(toSave!=null){
                toSave.forEach((item){
                  if(statusMap!=null && statusMap[item.SyncId]!=null && statusMap[item.SyncId].startsWith('E')){
                    //ERROR
                    var err = new ErrorSyncDesc();
                    err.errorStatus = statusMap[item.SyncId];
                    err.localItem = item;
                    response.errors.add(err);
                    if(changed!=null){
                      changed.forEach((itemMap){
                        if(item.Id == itemMap['Id'] || item.SyncId == itemMap['SyncId']){
                          err.serverItem = itemMap;
                        }else{
                          changedOK.add(itemMap);
                        }
                      });
                    }                }
                });
              }

              _processChanges(changedOK).then((_){
                //AllIDs
                var allIDs = resp.respObj['AllIDs'];
                if(allIDs!=null){ //TODO overit, ze ked je uplna chyba, tak allIDS je null, ked je empty, tak to znamena, ze je OK, ale user nema data
                  //add IDs that were not successfully synchronized (prevent deletion)
                  response.errors.forEach((err){
                    if(!allIDs.contains(err.localItem.Id)){
                      allIDs.add(err.localItem.Id);
                    }
                  });
                  _processAllIDS(allIDs).then((_){
                    //store.version = int.parse("$newVersion", radix:10); //TODO is ok to set new version if errors?
                    if(processErrors){
                      processSyncErrors(response).then((recoveryResp){
                        //FINAL clean
                        store.isSync(deep: true);
                        c.complete(recoveryResp);
                        _syncCtrl.add(recoveryResp);

                      });
                    }else{
                      //FINAL clean
                      store.isSync(deep: true);
                      c.complete(response);
                      _syncCtrl.add(response);

                    }
                  });
                }else{
                  c.complete(response);
                  _syncCtrl.add(response);
                }
              });
            }
          }
        });
      });
    });
    return c.future;
  }


  Future<OperationResponse> processSyncErrors(OperationResponse resp){
    var c = new Completer<OperationResponse>();
    if(resp!=null && !resp.success && resp.errors!=null && resp.errors.isNotEmpty){
      var conflict = 0;
      var na = 0;
      var general = 0;
      resp.errors.forEach((err){
        if(err.errorStatus == 'EC'){
          //conflict
          conflict++;
        }else if(err.errorStatus == 'ENA'){
          //item not available
          na++;
        }else{
          general++;
        }
      });
      var errTxt = "Unable to synchronize!";
      if(conflict>0){
        errTxt += "<br>$conflict conflict${conflict==1?"":"s"} (Maybe other device changes?)";
      }
      if(na>0){
        errTxt += "<br>$na data inconsitence${na==1?"":"s"} (Ufff, sorry ;-()";
      }
      if(general>0){
        errTxt += "<br>$general not available${general==1?"":"s"} (Maybe other device deletions?)";
      }
      ctx.mask.mask(
          maskIcon: MaskIcon.ERROR,
          text:'$errTxt <br>Perform recovery? ' ,
          mode: MaskMode.YESNO).then((resp3){
        if(resp3 == MaskComplete.YES){
          //if yes
          ctx.mask.mask(text: 'Recovering data from server...');
          recovery(processErrors: false).then((OperationResponse resp2){
            if(resp2.success){
              //ok
              ctx.mask.mask(maskIcon: MaskIcon.INFO, text: 'Recovery done.');
              ctx.mask.umMaskDefer().then((_){
                resp.recoverySuccess = true;
                resp.recoveryErrors = resp2.errors;
                c.complete(resp);
              });
            }else{
              //notok
              ctx.mask.mask(maskIcon: MaskIcon.ERROR, text: 'Recovery failed.', mode:MaskMode.OK).then((_){
                resp.recoverySuccess = false;
                resp.recoveryErrors = resp2.errors;
                c.complete(resp);
              });
            }
          });
        }else{
          resp.recoverySuccess = false;
          c.complete(resp);
        }
      });
    }
    return c.future;
  }

  ///MAIN recovery process
  Future<OperationResponse> recovery({bool processErrors : false}){
    var c = new Completer<OperationResponse>();
    store.batchStartCtrl.add(true);
    store.clear().then((ok){
      if(ok){
        sync(processErrors:processErrors, partOfRecovery: true).then((resp){
          c.complete(resp);
          store.batchEndCtrl.add(true);
        });
      }else{
        var resp = new OperationResponse()..success = false..recoverySuccess=false;
        c.complete(resp);
        store.batchEndCtrl.add(true);
      }
    });
    return c.future;
  }


  ///1. get not synchronized data
  Future<List<GeneralDO>> prepareSyncData(){
    var c = new Completer();
    store.getAll(inclDeleted:true).then((items){
      //var childFutures = new List();
      var toSave = new List();
      if(items!=null && items.isNotEmpty){
        //for each child
        items.forEach((item){
          if(item.Sync != GeneralDO.SYNC_OK){
            toSave.add(item);
          }
        });
      }
      c.complete(toSave);
    });
    return c.future;
  }

  ///3.process changes from sync request
  Future _processChanges(List<Map> changed){
    LOG.finest('SYNC - changes - start.');
    var c = new Completer();
    if(changed!=null){
      var childFutures = new List();
      changed.forEach((itemMap){
        var id;
        if(itemMap['SyncId']!=null){
          id = itemMap['SyncId'];
        }else{
          id = itemMap['Id'];
        }

        var c2 = new Completer();
        var serverItem = fromJsonMap(itemMap);
        var f = store.merge(item:serverItem, oldId:id);
        childFutures.add(f);
      });
      Future.wait(childFutures).then((_){
        LOG.finest('SYNC - changes - done.');
        c.complete();
      });
    }else{
      c.complete();
    }
    return c.future;
  }

  ///4. process allids from sync request
  Future _processAllIDS(List<String> allIDs){
    LOG.finest('SYNC - allids - start.');
    var c = new Completer();
    store.getAll(inclDeleted: true).then((items){
      var childFutures = new List();
      if(items!=null){
        //find all to remove
        var itemsToRemove = new List();
        items.forEach((item){
          if(allIDs==null || !allIDs.contains(item.Id)){
            itemsToRemove.add(item);
          }else{
            allIDs.remove(item.Id);
          }
        });
        //remove if found any
        itemsToRemove.forEach((item){
          var f = store.remove(item, sync: true);
          childFutures.add(f);
        });
        //final check
        if(allIDs!=null && allIDs.isNotEmpty){
          allIDs.forEach((id){
            LOG.finest('SYNC - allids - PROBLEM - ID:${id} - syncUrl: ${syncUrl}');
          });
        }
      }
      Future.wait(childFutures).then((_){
        LOG.finest('SYNC - allids - done.');
        c.complete();
      });
    });
    return c.future;
  }
  ///2. process sync request to server
  Future<HttpResp> _sync(String url, List<GeneralDO> items, int version, [String method = "POST"]){
    var data = new SyncReqData();
    if(items!=null && items.isNotEmpty){
      items.forEach((item){
        item.SyncId = item.Id;
        //create
        if(item.Sync == GeneralDO.SYNC_CREATE){
          if(data.create == null){
            data.create = new List();
          }
          item.SyncId = item.Id;
          data.create.add(item);
        }
        //update
        if(item.Sync == GeneralDO.SYNC_UPDATE){
          if(data.update == null){
            data.update = new List();
          }
          data.update.add(item);
        }
        //delete
        if(item.Sync == GeneralDO.SYNC_DELETE){
          if(data.delete == null){
            data.delete = new List();
          }
          data.delete.add(item);
        }
      });
    }
    data.version = version;
    var json = data.toJson();
    return send2Token(url,method:method, data:json);
  }

}