import 'package:engine/api/http/http.dart';
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

class TypedAdaptiveClient implements TypedAdaptiveClientAbstract {
  @override
  http.Client getClient([bool anonymous = false]) {
    return BrowserClient()..withCredentials = !anonymous;
  }
}
