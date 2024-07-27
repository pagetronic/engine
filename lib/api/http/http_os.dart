import 'package:engine/api/http/http.dart';
import 'package:http/http.dart' as http;

class TypedAdaptiveClient implements TypedAdaptiveClientAbstract {
  @override
  http.Client getClient([bool anonymous = false]) {
    return http.Client();
  }
}
