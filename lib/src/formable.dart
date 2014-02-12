part of itinnutil;

class DOForm {


  void initForm(){
    if(storage!=null){
      //TODO this is only one time
      //TODO onRemove
      storage.onUpdate.listen((dbItem){
        if(item!=null && item!=dbItem && dbItem.Id == item.Id){
          applyDbChanges(dbItem);
        }
      });
      storage.onIdChange.listen((StoreChange dbChange){
        if(item!=null && dbChange.oldId == item.Id){
          ItinnUtilContext.instance.LOG.fine("Updating item behind form, because id has been changed. $this ${dbChange.oldId}");
          storage.getById(dbChange.newId).then((dbItem){
            item.merge(dbItem);
          });
        }
      });
    }else{
      ItinnUtilContext.instance.LOG.severe("Storage is not defined for FormDO $this");
    }

    if(item!=null){
      item.changes.listen(applyModelChanges);
    }else{
      ItinnUtilContext.instance.LOG.severe("Model is not defined for FormDO $this");
    }

  }

  SyncStorage storage;

  @observable GeneralDO item;

  void applyDbChanges(GeneralDO dbItem){
      item.merge(dbItem);
      ItinnUtilContext.instance.LOG.fine("Updating item behind form, because it was changed. $this $dbItem");
  }
  void applyModelChanges(records){
    deferSave();
  }

  int _deferSaveTime = 1000;
  Timer _saveTimer;
  //save item related to this form
  Future deferSave(){
    if(_saveTimer!=null && _saveTimer.isActive){
      _saveTimer.cancel();
    }
    _saveTimer = new Timer(new Duration(milliseconds: _deferSaveTime), save);
  }
  Future save(){
    if(item.Id!=null && item.Id.isNotEmpty){
      return storage.update(item).then((item){
          //fire(EVENT_CLIENTSAVE, detail: item);
        });
    }else{
      return storage.insert(item).then((i){
           item.merge(i);
        });
    }
  }

  String uiDateTime(int date){
    return Util.toUIDateTime(date);
  }
  String uiDate(int date){
    return Util.toUIDate(date);
  }
  String uiTime(int date){
    return Util.toUITime(date);
  }

}