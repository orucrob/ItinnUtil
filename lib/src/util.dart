part of itinnutil;

class Util{

  ///get random string
  static String randomStrings(num length) {
    var rnd = new Random();
    var testVals = new Set<String>();
    int a = 'a'.codeUnitAt(0);
    var buffer = new StringBuffer();
    for(int k = 0; k<length; k++) {
      int randomChar = rnd.nextInt(26) + a;
      buffer.writeCharCode(randomChar);
    }
    return buffer.toString();
  }

  static StreamSubscription cancelSS(StreamSubscription ss){
    if(ss!=null){
      ss.cancel();
    }
    return null;
  }

  static String toUIDateTime(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('dd.MM.yyyy HH:mm').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static String toUIDate(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('dd.MM.yyyy').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static String toUIShortDate(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('dd.MM').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static String toUITime(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('HH:mm').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static String toInputDateTime(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('yyyy-MM-ddTHH:mm').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static String toInputTime(int date){
    if(date==null || date == 0){
      return "";
    }else{
      return new DateFormat('HH:mm').format(new DateTime.fromMillisecondsSinceEpoch(date, isUtc: false));
    }
  }
  static int fromInputDate(String date){
    if(date==null || date.isEmpty){
      return null;
    }else{
      try{
        return new DateFormat('yyyy-MM-dd').parse(date).toUtc().millisecondsSinceEpoch;
      }catch(e){
        ItinnUtilContext.instance.LOG.warning('Unable to parsse date $date according to InputDate format');
        return null;
      }
    }
  }
  static int fromInputDateTime(String date){
    if(date==null || date.isEmpty){
      return null;
    }else{
      try{
        return new DateFormat('yyyy-MM-ddTHH:mm').parse(date).toUtc().millisecondsSinceEpoch;
      }catch(e){
        ItinnUtilContext.instance.LOG.warning('Unable to parsse date $date according to InputDateTime format');
        return null;
      }
    }
  }
  static DateTime clearTime(DateTime d){
    if(d==null) return d;
    return d.subtract(new Duration(microseconds: d.millisecond, seconds: d.second, minutes: d.minute, hours: d.hour));
  }

  static Future show(Element el){
    var c = new Completer();
    if(el!=null){
      el.classes.remove("hide");
      //new Timer(new Duration(milliseconds:10),(){
      waitToDraw().then((_){
        el.classes..add("on")..remove("off");
        c.complete();
      });

      //});
    }
    return c.future;
  }
  static Future hide(Element el, [bool immediate = false]){
    return hideFull(el, immediate)[0];
  }
  static List hideFull(Element el, [bool immediate = false]){
    var c = new Completer();
    var hideSubs;
    if(el!=null){
      if(el.classes.contains('on')){
        if(immediate){
          el.classes..addAll(["off", 'hide'])..remove("on");
          c.complete();
        }else{
          hideSubs = el.onTransitionEnd.take(1).listen((event){
            if(el.classes.contains('off')){
              el.classes.add("hide");
              c.complete();
            }
          });
          el.classes..add("off")..remove("on");
        }
      }else{
        c.complete();
      }
    }else{
      c.complete();
    }
    return [c.future, hideSubs];
  }
  static Future waitToDraw(){
    var c = new Completer();
    window.requestAnimationFrame((_){
      //deffer next animation fram (to apply draw at first)
      window.requestAnimationFrame((_){
        c.complete();
      });
    });
    return c.future;
  }

}

