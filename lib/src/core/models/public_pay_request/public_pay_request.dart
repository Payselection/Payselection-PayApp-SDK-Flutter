import 'dart:convert';
import 'package:payselection_sdk/payselection.dart';
import '../../../constants.dart';
import '../../../utils/crypto_module.dart';
import '../payselection_request/payselection_request.dart';
import '../receipt_data/receipt_data.dart';

class PublicPayRequest extends PaySelectionRequest {
  String orderId;
  String description;
  String amount;
  String currency;
  CardDetails? cardDetails;
  CustomerInfo customerInfo;
  PaymentMethod paymentMethod;
  bool rebillFlag;
  ExtraData? extraData;
  ReceiptData? receiptData;
  String? payToken;

  PublicPayRequest(
      {required this.orderId,
      required this.description,
      required this.amount,
      required this.currency,
      this.cardDetails,
      required this.paymentMethod,
      required this.customerInfo,
      required this.rebillFlag,
      this.extraData,
      this.receiptData,
      this.payToken});

  @override
  Map<String, dynamic> toJson(
    String pKey,
    String pKeyRsa,
  ) =>
      {
        'OrderId': orderId,
        'Description': description,
        'Amount': amount,
        'Currency': currency,
        "PaymentMethod": resolvePaymentMethod(paymentMethod),
        if (paymentMethod == PaymentMethod.cryptogram && cardDetails != null)
          'PaymentDetails': PaymentDetailsCryptogram(
            value: createCryptogram(
              PaymentData(
                cardDetails: cardDetails!,
                messageExpiration: messageExpiration(),
                transactionDetails: TransactionDetails(
                  amount: amount,
                  currency: currency,
                ),
              ),
              pKey,
            ),
          ).toJson()
        else if (paymentMethod == PaymentMethod.cryptogramRSA  && cardDetails != null)
          'PaymentDetails': PaymentDetailsCryptogramRSA(
            value: createCryptogramRsa(
              PaymentData(
                cardDetails: cardDetails!,
                messageExpiration: messageExpiration(),
                transactionDetails: TransactionDetails(
                  amount: amount,
                  currency: currency,
                ),
              ),
              pKeyRsa,
            ),
          ).toJson()
        else if (paymentMethod == PaymentMethod.token)
          'PaymentDetails': PaymentDetailsToken(
            type: 'Yandex',
            payToken: payToken,
          ),
        'CustomerInfo': customerInfo.toJson(),
        if (extraData != null) "ExtraData": extraData?.toJson(),
        'rebillFlag': rebillFlag,
        if (receiptData != null) 'ReceiptData': receiptData?.toJson()
      };

  String createCryptogram(PaymentData data, String publicKey) {
    return Encryption().createCryptogram(
      jsonEncode(data).toString(),
      publicKey,
    );
  }

  String createCryptogramRsa(PaymentData data, String publicKeyRsa) {
    return Encryption().createCryptogramRsa(
      jsonEncode(data).toString(),
      publicKeyRsa,
    );
  }

  int messageExpiration() {
    final int expiration = const Duration(days: 1).inMilliseconds;
    int messageExpiration =
        (DateTime.now().millisecondsSinceEpoch + expiration);
    return messageExpiration;
  }

  String resolvePaymentMethod(PaymentMethod pMethod) {
    switch (pMethod) {
      case PaymentMethod.cryptogram:
        return 'Cryptogram';
      case PaymentMethod.qr:
        return 'QR';
      case PaymentMethod.token:
        return 'Token';
      case PaymentMethod.sberPay:
        return 'SberPay';
      case PaymentMethod.externalForm:
        return 'ExternalForm';
      case PaymentMethod.cryptogramRSA:
        return 'CryptogramRSA';
    }
  }

  @override
  String get apiMethod => ApiMethods.publicPay;

  @override
  String get httpMethod => HttpMethods.post;
}

class PaymentDetailsCryptogram {
  String value;

  PaymentDetailsCryptogram({
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'Value': value,
      };
}

class PaymentDetailsCryptogramRSA {
  String value;

  PaymentDetailsCryptogramRSA({
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'Value': value,
      };
}

class PaymentDetailsToken {
  String type;
  String? payToken;

  PaymentDetailsToken({
    required this.type,
    required this.payToken,
  });

  Map<String, dynamic> toJson() => {
        'Type': type,
        'PayToken': payToken ?? '',
      };
}

enum PaymentMethod {
  cryptogram,
  qr,
  token,
  sberPay,
  externalForm,
  cryptogramRSA
}

class ExtraData {
  String? returnUrl;
  String? webhookUrl;
  String? screenHeight;
  String? screenWidth;
  String? challengeWindowSize;
  String? timeZoneOffset;
  String? colorDepth;
  String? region;
  String? userAgent;
  String? acceptHeader;
  bool? javaEnabled;
  bool? javaScriptEnabled;

  ExtraData({
    this.returnUrl,
    this.webhookUrl,
    this.screenHeight,
    this.screenWidth,
    this.challengeWindowSize,
    this.timeZoneOffset,
    this.colorDepth,
    this.region,
    this.userAgent,
    this.acceptHeader,
    this.javaEnabled,
    this.javaScriptEnabled,
  });

  factory ExtraData.fromJson(Map<String, dynamic> json) => ExtraData(
        returnUrl: json["ReturnUrl"],
        webhookUrl: json["WebhookUrl"],
        screenHeight: json["ScreenHeight"],
        screenWidth: json["ScreenWidth"],
        challengeWindowSize: json["ChallengeWindowSize"],
        timeZoneOffset: json["TimeZoneOffset"],
        colorDepth: json["ColorDepth"],
        region: json["Region"],
        userAgent: json["UserAgent"],
        acceptHeader: json["acceptHeader"],
        javaEnabled: json["JavaEnabled"],
        javaScriptEnabled: json["javaScriptEnabled"],
      );

  Map<String, dynamic> toJson() => {
        if (returnUrl != null) "ReturnUrl": returnUrl,
        if (webhookUrl != null) "WebhookUrl": webhookUrl,
        if (screenHeight != null) "ScreenHeight": screenHeight,
        if (screenWidth != null) "ScreenWidth": screenWidth,
        if (challengeWindowSize != null)
          "ChallengeWindowSize": challengeWindowSize,
        if (timeZoneOffset != null) "TimeZoneOffset": timeZoneOffset,
        if (colorDepth != null) "ColorDepth": colorDepth,
        if (region != null) "Region": region,
        if (userAgent != null) "UserAgent": userAgent,
        if (acceptHeader != null) "acceptHeader": acceptHeader,
        if (javaEnabled != null) "JavaEnabled": javaEnabled,
        if (javaScriptEnabled != null) "javaScriptEnabled": javaScriptEnabled,
      };
}
