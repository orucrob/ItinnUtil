library all_tests;

import 'package:unittest/unittest.dart';
import 'package:logging/logging.dart';
import 'package:itinnutil/itinnutil.dart';
import 'package:itinndata/itinndata.dart';
import 'dart:async';

run() {
  group('create objects',(){
    var ctx = ItinnUtilContext.instance;
    ctx.mask = new TestMask();
  });

  group('initialization',(){
    test('first init',(){
      var ctx = ItinnUtilContext.instance;
      var f = ctx.init().then((ok){
        expect(ctx.storage, isNotNull);
        expect(ctx.server, isNotNull);
        return ok;
      });
      expect(f, completion(true));
      return f;
    });

    test('clear init',(){
      var ctx = ItinnUtilContext.instance;
      var f = ctx.storage.clearAll(deep: true).then((_){
        return ctx.init().then((ok){
          expect(ctx.storage, isNotNull);
          expect(ctx.server, isNotNull);
          return ok;
        });
      });
      expect(f, completion(true));
      return f;
    });

    test('server init',(){
      var ctx = ItinnUtilContext.instance;
      var f = ctx.storage.settAction((sett){
        sett.me = new UserDO();
        //sett.me.LoginID = "test";
        sett.token = 'BOTEBUICPT';
        sett.offline = false;
      }).then((_){
        return ctx.init().then((ok){
          expect(ctx.storage, isNotNull);
          expect(ctx.server, isNotNull);
          return ok;
        });
      });
      expect(f, completion(true));
      new Timer(new Duration(milliseconds:1000), (){
        var mask = ctx.mask;
        if(mask is TestMask && mask.c!=null){
          mask._complete(MaskComplete.OK); //401 -> OK
        }
      });
      return f;
    });
  });
}
//LocalSettingsDO

main() {
  var ctrl;

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) {
      print('${rec.level.name}: ${rec.loggerName}: ${rec.time}: ${rec.message}');
  });

  group('run', () {
    run();
  });
}




//TEST MASK IMPL
class TestMask extends Mask{
  Completer<MaskComplete> c;

  Future _getNewFuture(){
    if(c!=null){
      c.complete(MaskComplete.UNKNOWN);
    }
    c = new Completer();
    return c.future;
  }
  Future _complete(MaskComplete completeStatus){
    if(c!=null){
      c.complete(completeStatus);
      var ret =c.future;
      c = null;
      return ret;
    }else{
      return new Future.value(completeStatus);
    }
  }
  void setLocale(String locale){
//nothing
  }

  Future<MaskComplete> maskWithMsg (List<MaskMsg> msg){
    print('TESTMASK : maskWithMsg $msg');
    return _getNewFuture();
  }
  Future<MaskComplete> mask ({MaskIcon maskIcon, String text:'loading...', MaskMode mode, bool unMaskDefer:false}){
    print('TESTMASK : mask $maskIcon  $text  $mode');
    return _getNewFuture();
  }
  Future unMaskDefer({int wait: 500, MaskComplete completeStatus}){
    print('TESTMASK : umMaskDefer $wait $completeStatus');
    return _complete(completeStatus);

  }
  Future unMaskDeferNoBtt({int wait: 500, MaskComplete completeStatus}){
    print('TESTMASK : unMaskDeferNoBtt $wait $completeStatus');
    return _complete(completeStatus);

  }
  Future unMaskNoBtt([MaskComplete completeStatus]){
    print('TESTMASK : unMaskNoBtt $completeStatus');
    return _complete(completeStatus);
  }
  Future unMask([MaskComplete completeStatus ]){
    print('TESTMASK : unMask $completeStatus');
    return _complete(completeStatus);
  }
}
