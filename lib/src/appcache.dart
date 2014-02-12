part of itinnutil;

class AppCache {

  ApplicationCache appCache;

  AppCache(this.appCache) {
    // Set up handlers to log all of the cache events or errors.
    appCache.onCached.listen(onCacheEvent);
    appCache.onChecking.listen(onCacheEvent);
    appCache.onDownloading.listen(onCacheEvent);
    appCache.onError.listen(onCacheError);
    appCache.onNoUpdate.listen(onCacheEvent);
    appCache.onObsolete.listen(onCacheEvent);
    appCache.onProgress.listen(onCacheEvent);

    // Set up a more interesting handler to swap in the new app when ready.
    appCache.onUpdateReady.listen((e) => updateReady());
  }

  void updateReady() {
    if (appCache.status == ApplicationCache.UPDATEREADY) {
      // The browser downloaded a new app cache. Alert the user and swap it in
      // to get the new hotness.
      appCache.swapCache();

      // TODO(jason9t): window.location.reload() is blocked by this bug:
      // https://code.google.com/p/dart/issues/detail?id=5551
      // So for now we'll just advise the user to refresh manually.
      // if (window.confirm('A new version of this site is available. Reload?')) {
      //   window.location.reload();
      // }
      //window.alert('A new version of this site is available. Please reload.');
      window.location.reload();
    }
  }

  void onCacheEvent(Event e) {
    print('Cache event: ${e}');
  }

  void onCacheError(Event e) {
    // For the sake of this sample alert the reader that an error has occurred.
    // Of course we would *never* do it this way in real life.
    //TODO there is an error?!?!
    //window.alert("Oh no! A cache error occurred: ${e}");
    print('Cache error: ${e}');
  }
}
