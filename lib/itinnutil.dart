library itinnutil;

import "dart:core" hide override;
import 'dart:html';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
//import 'dart:typed_data';
import 'dart:html_common';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:logging/logging.dart';

@MirrorsUsed(targets: 'MaskMode,MaskIcon')
import 'dart:mirrors';

//import 'dart:indexed_db' as idb;
//import 'dart:web_sql' as sql;
import 'package:itinndata/itinndata.dart';
import 'package:observe/observe.dart';
//import 'package:polymer/polymer.dart';

//part "layout/layout.dart";

part "src/server.dart";
part "src/syncserver.dart";
part "src/servercontrol.dart";
part "src/servermodel.dart";
part "src/initialization.dart";
part "src/eventbus.dart";
part "src/accountmanager.dart";
part "src/formable.dart";
part "src/appcache.dart";


//part "data/storage.dart";
//part "data/data.dart";
//part "data/localdata.dart";
//part "data/store_settings.dart";

//part "gui/base/component.dart";
//part "gui/base/form.dart";
//part "gui/base/page.dart";
//part "gui/base/fields/button.dart";
//part "gui/base/fields/field.dart";
//part "gui/base/fields/input.dart";
//part "gui/base/fields/checkbox.dart";
//part "gui/menu/menu.dart";
//part "gui/account/register.dart";
//part "gui/account/login.dart";
//part "gui/settings/settings.dart";
//part "gui/settings/account.dart";
//part "gui/users/list.dart";
//part "gui/users/form.dart";
//
part "src/mask.dart";
//part "app/roleutil.dart";
part "src/util.dart";
part "src/i18n.dart";


//part "app.dart";
//part "gui/base/btt/actionbutton.dart";
//part "gui/base/fastclickcmp.dart";
//part "gui/base/movablecmp.dart";




class ItinnUtilContext {
  static ItinnUtilContext i;

  static ItinnUtilContext get instance{
    if(i==null){
      i = new ItinnUtilContext();
    }
    return i;
  }

  ItinnUtilContext();

  ///access to localized messages
  final ItinnI18n i18n = new ItinnI18n._();

  ///logger for library
  Logger LOG = new Logger('itinnutil');

  ///name of DB
  String dbName = "itinnDb";

  ///common data control object
  StorageCtrl storage;

  ///common data control object
  ServerCtrl server;

  ///common initialization object
  Initialization initialization;

  EventBus bus;


  ///mask object to handle user interaction and messages
  Mask mask;

  bool server401 = false;
  bool serverMode = false;
  bool offlineMode = false;
  bool moreAnim = false;
  final bool ANDROID = false;
//  static const bool DEBUG = true;
  //final String SERVER = "http://192.168.1.20:8080";
  //final String SERVER = "http://192.168.22.170:8080";
  //final String SERVER = "http://2.itinngoapps.appspot.com";
  //final String SERVER = "http://localhost:8080";
  final String SERVER = "";
  //final String SERVER = "http://192.168.22.170:8000";
  //final String SERVER = "http://192.168.1.11:8000";

  DivElement uiLogEl;
  DivElement statusEl;



  Future<bool> init({Mask mask, DivElement uiLogEl}){
    storage = new StorageCtrl(dbName);
    server = new ServerCtrl("appid");
    initialization = new Initialization();
    bus = new EventBus();
    if(uiLogEl!=null){
      this.uiLogEl = uiLogEl;
    }
    if(mask!=null){
      this.mask = mask;
    }
    return storage.init().then((ok){
      if(!ok){
        return false;
      }else{
        return initialization.init();
      }
    });
  }

  void uilog(String txt){
    if(uiLogEl!=null){
      DivElement txtEl = new DivElement()..classes=['app-log-txt']..text = txt;
      if(!uiLogEl.classes.contains('on')) {
        Util.show(uiLogEl);
      }
      uiLogEl.append(txtEl);

//      txtEl.onClick.listen((_){
//        txtEl.remove();
//        if(uiLogEl.children.isEmpty){
//          Util.hide(uiLogEl, true);
//        }
//      });
      new Timer(new Duration(seconds:5),(){
        txtEl.remove();
        if(uiLogEl.children.isEmpty){
          Util.hide(uiLogEl, true);
        }
      });
    }
  }

  int start = new DateTime.now().millisecondsSinceEpoch;
  void perfLog(String txt, {bool restart:false}){
//TODO remove all calls -> this is only for dev
//    int now = new DateTime.now().millisecondsSinceEpoch;
//    if(restart){
//      start = now;
//    }
//    uilog("${now-start}ms: $txt");
  }

  Timer _statusTimer;
  void status(String txt){
    if(statusEl!=null){
      if(_statusTimer!=null && _statusTimer.isActive){
        _statusTimer.cancel();
      }
      if(txt==null || txt.isEmpty){
        if(statusEl.classes.contains('on')) {
          Util.hide(statusEl, true);
        }
      }else{
        DivElement txtEl;
        if(statusEl.children.length>0){
          txtEl = statusEl.children[0];
        }else{
          txtEl = new DivElement()..classes=['app-status-txt'];
          statusEl.append(txtEl);
        }
        txtEl.text = txt;

        if(!statusEl.classes.contains('on')) {
          Util.show(statusEl);
        }
        _statusTimer = new Timer(new Duration(seconds:5),(){
            Util.hide(statusEl, true);
        });
      }
    }
  }


}



//App app;
//
//class ImageUtil{
//
//  ///Conver base64 [dataUrl] to [Blob]
//  static Blob dataUrlToBlob(String dataUrl){
//
//    var byteString = Base64String.decode(dataUrl.split(',')[1]);
//    var mimeString = dataUrl.split(',')[0].split(':')[1].split(';')[0];
//     // var ab = new ArrayBuffer(byteString.length);
//     var ia = new Uint8List(byteString.length);
//     for (var i = 0; i < byteString.length; i++) {
//        ia[i] = byteString.codeUnitAt(i);
//     }
//
//    var blob =  new Blob([ia], mimeString );
//    return blob;
//  }
//
//}
//class Base64String {
//  static const List<String> _encodingTable = const [
//      'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
//      'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd',
//      'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's',
//      't', 'u', 'v', 'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7',
//      '8', '9', '+', '/'];
//
//  static String encode(String income ) {
//
//    List<int> data = income.codeUnits;
//
//    List<String> characters = new List<String>();
//    int i;
//    for (i = 0; i + 3 <= data.length; i += 3) {
//      int value = 0;
//      value |= data[i + 2];
//      value |= data[i + 1] << 8;
//      value |= data[i] << 16;
//      for (int j = 0; j < 4; j++) {
//        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
//        characters.add(_encodingTable[index]);
//      }
//    }
//    // Remainders.
//    if (i + 2 == data.length) {
//      int value = 0;
//      value |= data[i + 1] << 8;
//      value |= data[i] << 16;
//      for (int j = 0; j < 3; j++) {
//        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
//        characters.add(_encodingTable[index]);
//      }
//      characters.add("=");
//    } else if (i + 1 == data.length) {
//      int value = 0;
//      value |= data[i] << 16;
//      for (int j = 0; j < 2; j++) {
//        int index = (value >> ((3 - j) * 6)) & ((1 << 6) - 1);
//        characters.add(_encodingTable[index]);
//      }
//      characters.add("=");
//      characters.add("=");
//    }
//    StringBuffer output = new StringBuffer();
//    for (i = 0; i < characters.length; i++) {
//      if (i > 0 && i % 76 == 0) {
//        output.write("\r\n");
//      }
//      output.write(characters[i]);
//    }
//    return output.toString();
//  }
//
//
//  static String decode(String data) {
//    List<int> result = new List<int>();
//    int padCount = 0;
//    int charCount = 0;
//    int value = 0;
//    for (int i = 0; i < data.length; i++) {
//      int char = data.codeUnitAt(i);
//      if (65 <= char && char <= 90) {  // "A" - "Z".
//        value = (value << 6) | char - 65;
//        charCount++;
//      } else if (97 <= char && char <= 122) { // "a" - "z".
//        value = (value << 6) | char - 97 + 26;
//        charCount++;
//      } else if (48 <= char && char <= 57) {  // "0" - "9".
//        value = (value << 6) | char - 48 + 52;
//        charCount++;
//      } else if (char == 43) {  // "+".
//        value = (value << 6) | 62;
//        charCount++;
//      } else if (char == 47) {  // "/".
//        value = (value << 6) | 63;
//        charCount++;
//      } else if (char == 61) {  // "=".
//        value = (value << 6);
//        charCount++;
//        padCount++;
//      }
//      if (charCount == 4) {
//        result.add((value & 0xFF0000) >> 16);
//        if (padCount < 2) {
//          result.add((value & 0xFF00) >> 8);
//        }
//        if (padCount == 0) {
//          result.add(value & 0xFF);
//        }
//        charCount = 0;
//        value = 0;
//      }
//    }
//
//    return new String.fromCharCodes( result );
//  }
//}

class ElUtil{
  static void moveX(HtmlElement el, num pos, [num duration = 0, String unit='%'] ){
    el.style.transitionDuration = '${duration}ms';
    el.style.transitionProperty = '${Device.cssPrefix}transform';
    el.style.transform = 'translate3d($pos$unit,0,0)';
  }
  static void moveY(HtmlElement el, num pos, [num duration = 0, String unit='%'] ){
    el.style.transitionDuration = '${duration}ms';
    el.style.transitionProperty = '${Device.cssPrefix}transform';
    el.style.transform = 'translate3d(0, $pos$unit,0)';
  }
  static void move(HtmlElement el, num posX, num posY, num posZ, [num duration = 0, String unit='px'] ){
    el.style.transitionDuration = '${duration}ms';
    el.style.transitionProperty = '${Device.cssPrefix}transform';
    el.style.transform = 'translate3d($posX$unit,$posY$unit,$posZ$unit)';
  }
  static void moveClear(HtmlElement el){
    el.attributes.remove('style');
  }
  static void moveXClear(HtmlElement el){
    el.attributes.remove('style');
//    el.style.removeProperty('transitionDuration');
//    el.style.removeProperty('transitionProperty');
//    el.style.removeProperty('transform');
  }
  static void opacity(DivElement el, num val, [num duration = 0] ){
    el.style.transitionProperty = "opacity";
    el.style.transitionDuration = '${duration}ms';
    el.style.opacity = '$val';
  }
  static void opacityClear(HtmlElement el){
    el.attributes.remove('style');
//    el.style.removeProperty('transitionDuration');
//    el.style.removeProperty('transitionProperty');
//    el.style.removeProperty('opacity');
  }
  static void filter(DivElement el, String val, [num duration = 0] ){
   //-webkit-filter: blur(2px) grayscale(50%);
    el.attributes['style']= "transition-property: filter; ${Device.cssPrefix}transition-property: ${Device.cssPrefix}filter; transition-duration: ${duration}ms; ${Device.cssPrefix}transition-duration: ${duration}ms;filter: $val;${Device.cssPrefix}filter: $val;";
  }
  static void filterClear(HtmlElement el){
    el.attributes.remove('style');
  }
  ///get client x and y (Point) from event click or first touch
  static Point getClientXY(event){
    var mvMovingX, mvMovingY;
    if(TouchEvent.supported){
      if(event.touches.length>0){ //TODO touches by ID, not to skip fingers
        return event.touches[0].client;
      }else if(event.changedTouches.length>0){
        return event.changedTouches[0].client;
      }else{
        //TODO
        return null;//new Point();
      }
    }else{
      return event.client;
    }
  }
}