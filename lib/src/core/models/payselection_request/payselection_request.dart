
abstract class PaySelectionRequest {

  Map<String, dynamic> toJson(String pKey, String pKeyRsa) => {};

  String get httpMethod;

  String get apiMethod;

  String get apiMethodPath => '/$apiMethod';

}