import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'package:payselection_sdk/payselection.dart';
import 'package:payselection_sdk/src/constants.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:uuid/uuid.dart';
import '../core/models/payselection_request/payselection_request.dart';

class NetworkClient {
  const NetworkClient(this._config);

  final PaySelectionConfig _config;

  Future<Response> call<Response extends BaseResponse>(
      PaySelectionRequest request,
      Response Function(Map<String, dynamic> json) response) async {
    final PaySelectionConfig config = _config;

    final requestBody = jsonEncode(_modifyRequest(request, config));

    var requestId = const Uuid().v4();
    final settings = NetworkSettings(
        siteId: _siteId(config), reqId: requestId);

    late Map<String, String> headers;

    final url = Uri.parse(
        '${NetworkSettings.domain}${request.apiMethodPath}');
    http.Response rawResponse;
    try {
      if (request.httpMethod == "GET") {
        headers = {
          'X-REQUEST-AUTH': 'public',
          'X-SITE-ID': _siteId(config),
          'X-REQUEST-ID': requestId,
          'X-REQUEST-SIGNATURE': _generateSignature(request, requestId) ?? ''
        };
        rawResponse = await http.get(url, headers: headers);
      } else {
        headers = settings.baseHeaders();
        rawResponse = await http
            .post(
          url,
          headers: headers,
          body: requestBody,
        )
            .timeout(NetworkSettings.timeout);
      }
      if (config.isDebug) {
        config.logger
            .log(message: url.toString(), name: 'Request URL');
        config.logger.log(
            message: headers.toString(), name: 'Request headers');
        config.logger.log(message: requestBody, name: 'RawRequest');
      }
    } catch (e) {
      debugPrint('Error making payment request: $e');
      rethrow;
    }
    late Response response0;

    final dynamic json = jsonDecode(rawResponse.body);
    response0 = response(json as Map<String, dynamic>);

    if (config.isDebug) {
      config.logger.log(
          message: "${rawResponse.statusCode} | ${rawResponse.body}",
          name: 'RawResponse');
    }

    return response0;
  }

  Map<String, dynamic> _modifyRequest(
      PaySelectionRequest request,
      PaySelectionConfig config,
      ) {
    switch (config) {
      case PaySelectionConfigCredential():
        return request.toJson(config.publicKey, config.publicRsaKey);
    }
  }

  String _siteId(PaySelectionConfig config) {
    switch (config) {
      case PaySelectionConfigCredential():
        return config.xSiteId;
    }
  }


  String? _generateSignature(PaySelectionRequest request, String xReqId) {
    if (request is TransactionStatusRequest) {
      final config = _config as PaySelectionConfigCredential;
      final value =
          '${request.httpMethod}\n'
          '${request.apiMethodPath}\n'
          '${config.xSiteId}\n'
          '$xReqId\n';

      final keyBytes = utf8.encode(request.transactionSecretKey);
      final key = KeyParameter(Uint8List.fromList(keyBytes));
      final hmacSha256 = HMac(SHA256Digest(), 64)..init(key);

      final valueBytes = utf8.encode(value);
      final listBytes = Uint8List.fromList(valueBytes);

      var i = hmacSha256.process(listBytes);

      return bytesToHex(i);
    }

    return null;
  }

  String bytesToHex(List<int> bytes) {
    return bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}
