part of itinnutil;

class EventBus {
  static const String EV_LOGIN="ev_login";
  static const String EV_LOGOUT="ev_logout";

  final _map = {};

  Stream stream(String eventType){
    _map.putIfAbsent(eventType, () => new StreamController());
    return _map[eventType].stream;
  }

  EventSink sink(String eventType){
    _map.putIfAbsent(eventType, () => new StreamController());
    return _map[eventType].sink;
  }

  StreamSubscription listen(String eventType, callback) =>
  stream(eventType).listen(callback);

  fire(String eventType, event) =>
  sink(eventType).add(event);
}