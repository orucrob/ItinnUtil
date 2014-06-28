part of itinnutil;

abstract class Mask{
  Future<MaskComplete> maskWithMsg (List<MaskMsg> msg);
  Future<MaskComplete> mask ({MaskIcon maskIcon, String text:'loading...', MaskMode mode, bool unMaskDefer: false});
  Future unMaskDefer({int wait: 500, MaskComplete completeStatus});
  Future unMaskDeferNoBtt({int wait: 500, MaskComplete completeStatus});
  Future unMaskNoBtt([MaskComplete completeStatus]);
  Future unMask([MaskComplete completeStatus ]);
  void setLocale(String locale);
}

class MaskIcon extends Object{
//  static const INFO = const MaskIcon._("x-appmask-info-icon");
//  static const WARN = const MaskIcon._("x-appmask-warn-icon");
//  static const ERROR = const MaskIcon._("x-appmask-error-icon");
//  static const LOADING = const MaskIcon._("x-appmask-loading-icon");
//  static const QUESTION = const MaskIcon._("x-appmask-question-icon");
//  static const CODE = const MaskIcon._("x-appmask-code-icon");
  static var INFO = new MaskIcon._("icon-info", "");
  static var WARN = new MaskIcon._("icon-warn", "");
  static var ERROR = new MaskIcon._("icon-error", "pulse");
  static var LOADING = new MaskIcon._("icon-sync", "rotate");
  static var QUESTION = new MaskIcon._("icon-question", "");
  static var CODE = new MaskIcon._("icon-lock", "");
  static get values => [INFO.value, WARN.value,ERROR.value,LOADING.value,QUESTION.value, CODE.value];
  final String value;
  final String effect;
  MaskIcon._(this.value, this.effect);
}
class MaskComplete extends Object {
  static var CANCEL = new MaskComplete._("cancel");
  static var OK = new MaskComplete._("ok");
  static var YES = new MaskComplete._("yes");
  static var NO = new MaskComplete._("no");
  static var UNKNOWN = new MaskComplete._("unknown");
  static get values => [CANCEL.value, OK.value,YES.value,NO.value,UNKNOWN.value];
  final String value;
  MaskComplete._(this.value);
}

class MaskMode extends Object {
  static var NOBTT = new MaskMode._('nobtt-mode');
  static var YESNO = new MaskMode._('yesno-mode');
  static var OK = new MaskMode._('ok-mode');
  static var OKCANCEL = new MaskMode._('okcancel-mode');
  static get values => [NOBTT.value, YESNO.value, OK.value, OKCANCEL.value];
  final String value;
  MaskMode._(this.value);
}

class MaskMsg {
  static const TYPE_E = "E";
  static const TYPE_W = "W";
  static const TYPE_I = "I";
  String Code ;
  String Type;
  String DefTxt;
  MaskMsg(this.Code, this.Type, this.DefTxt);

  MaskMsg.fromJsonMap(Map jsonMap){
    this.Code = jsonMap['DefTxt'];
    this.Type = jsonMap['Type'];
    this.DefTxt = jsonMap['DefTxt'];
  }
  static List<MaskMsg> transform(var jsonList){
    var list;
    if(jsonList!=null){
      if(jsonList is List){
        if(jsonList.isNotEmpty){
          list = new List();
          for(var jsonMap in jsonList ){
            list.add(new MaskMsg.fromJsonMap(jsonMap));
          }
        }
      }else if(jsonList is Map){
        list = new List();
        list.add(new MaskMsg.fromJsonMap(jsonList));
      }
    }
    return list;
  }
}