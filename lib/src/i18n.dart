part of itinnutil;


class ItinnI18n{
  ItinnI18n._();

  final pattern = new RegExp(r'\$[^\$]*\$');

  String defaultLocale = 'en';
  String locale = 'sk';

  String getMessage(String key,[ dynamic replacements]){
    return _getMessage(locale, key, replacements);
  }

  String _getMessage(String loc, String key,[ dynamic replacements]){
    String str = _trans[loc][key];
    if(str==null){
      ItinnUtilContext.instance.LOG.severe('Err: no trans for key: $key and locale: $loc');
      if(loc!=defaultLocale){
        str = _getMessage(defaultLocale, key, replacements);
      }else{
        str = key;
      }
    }else if(replacements !=null){
      if(replacements is String){
        str = str.replaceAll(pattern, replacements);
      }else if(replacements is Iterable){
        for(var rep in replacements){
          if(rep!=null){
            str = str.replaceFirst(pattern, rep);
          }
        }
      }
    }
    return str;
  }
  String operator [](String key) => getMessage(key);

  addTrans(Map trans){
    trans.forEach((lang, Map trans){
      _trans[lang].addAll(trans);
    });
  }
}

final _trans = {
  "en":{
    "iu.am.password.err1": "Passwords not equal!",
    "iu.am.signup.progress": "Creating user and logging in...",
    "iu.am.signup.failed": "Unable to create user!",
    "iu.am.signup.done": "User created.",
    "iu.am.signin.progress": "Logging in...",
    "iu.am.signin.failed": "Unable to log in!",
    "iu.am.signout.q": "Sign out from app?",
    "iu.am.signout.q2": "Save data to server before sign out?",
    "iu.am.signout.progress": "Signing out...",
    "iu.am.signout.done": "Done.",
    "iu.am.signout.failed": "Signing out failed!",
    "iu.am.signout.failed2": "Sorry, unable to save data!",

    "iu.am.removeprofileuser.q": "Remove user?",
    "iu.am.removeprofileuser.progress": "Removing user...",
    "iu.am.removeprofileuser.failed": "Removing user failed!",
    "iu.am.removeprofileuser.done": "Done.",

    "iu.am.changeroles.progress": "Changing role...",
    "iu.am.changeroles.failed": "Changing role failed!",
    "iu.am.changeroles.done": "Done.",

    "iu.sync.recoveryok": "Check your changes, please!",
    "iu.sync.ok": "Done.",
    "iu.sync.recoveryfailed": "Error while saving!",
    "iu.sync.err": "Unable to synchronize!",
    "iu.sync.err.desc1": "<br>\$conflict\$ conflict\$s\$ (Maybe other device changes?)",
    "iu.sync.err.desc2": "<br>\$na\$ data inconsitence\$s\$ (Ufff, sorry ;-()",
    "iu.sync.err.desc3": "<br>Number of not available records: \$general\$ (Maybe other device deletions?)",
    "iu.sync.err.descGeneral": "<br>Saving record faild with error : \$code\$.",
    "iu.sync.err.recovery.q": "<br>Perform recovery (remove all local data and load from server)?",

    "iu.sync.recovery.progress":"Recovering data from server...",
    "iu.sync.recovery.done":"Recovery done.",
    "iu.sync.recovery.failed":"Recovery failed!"
  },
  "sk":{
    "iu.am.password.err1": "Heslá sa nezhodujú!",
    "iu.am.signup.progress": "Užívateľ sa vytvára...",
    "iu.am.signup.failed": "Nepodarilo sa vytvoriť užívateľa!",
    "iu.am.signup.done": "Hotovo.",
    "iu.am.signin.progress": "Prihlasovanie...",
    "iu.am.signin.failed": "Nepodarilo sa prihlásiť!",
    "iu.am.signout.q": "Odhlásiť z aplikácie?",
    "iu.am.signout.q2": "Uložiť dáta na server pred odhlásením?",
    "iu.am.signout.progress": "Odhlasovanie...",
    "iu.am.signout.done": "Hotovo.",
    "iu.am.signout.failed": "Nepodarilo sa odhlásiť!",
    "iu.am.signout.failed2": "Dáta sa nepodarilo uložiť!",

    "iu.am.removeprofileuser.q": "Odstrániť užívateľa?",
    "iu.am.removeprofileuser.progress": "Užívateľ sa odstraňuje...",
    "iu.am.removeprofileuser.failed": "Nepodarilo sa odstrániť užívateľa!",
    "iu.am.removeprofileuser.done": "Hotovo.",

    "iu.am.changeroles.progress": "Rola sa mení...",
    "iu.am.changeroles.failed": "Nepodarilo sa zmeniť rolu!",
    "iu.am.changeroles.done": "Hotovo.",

    "iu.sync.recoveryok": "Vyskytli sa problému pri synchronizácii dát, systém sa ich pokúsil vyriešiť, avšak pre istotu skontrolujte vaše posledné zmeny.",
    "iu.sync.ok": "Hotovo.",
    "iu.sync.recoveryfailed": "Vyskytli sa problému pri synchronizácii dát!",
    "iu.sync.err": "Nepodarilo sa zosynchronizovať dáta.",
    "iu.sync.err.desc1": "<br>\$conflict\$ konfikt\$s\$ (Paralelné zmeny na inom zariadení?)",
    "iu.sync.err.desc2": "<br>Počet dátových nekonzistencií: \$na\$ (Ufff, sorry ;-()",
    "iu.sync.err.desc3": "<br>Počet neexistujúcich záznamov: \$general\$ (Paralelné zmazanie na inom zariadení?)",
    "iu.sync.err.descGeneral": "<br>Pri uložení záznamu sa vyskytla chyba: \$code\$.",
    "iu.sync.err.recovery.q": "<br>Vykonať obnovu dát (odstrániť všetky lokálne dáta a nahrať znovu zo servera)?",

    "iu.sync.recovery.progress":"Obnovovanie dát zo servera...",
    "iu.sync.recovery.done":"Obnova ukončená.",
    "iu.sync.recovery.failed":"Obnova zlyhala!"
  }
};

