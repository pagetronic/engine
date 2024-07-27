import 'package:engine/api/http/http_os.dart' if (dart.library.html) 'package:engine/api/http/http_web.dart' as client;
import 'package:http/http.dart' as http;

class AdaptiveClient {
  static final clientAdapted = client.TypedAdaptiveClient();

  static http.Client getClient([bool anonymous = false]) {
    // || UsersStore.user == null <= impossible
    return clientAdapted.getClient(anonymous);
  }
}

abstract class TypedAdaptiveClientAbstract {
  http.Client getClient([bool anonymous = false]);
}
