import '../../../../payselection.dart';

class BaseResponse<M> {
  BaseResponse(
      {this.code, this.description, this.addDetails, this.data});

  String? code;

  String? description;

  AddDetails? addDetails;

  M? data;

  factory BaseResponse.fromJson(Map<String, dynamic> json) {
    return BaseResponse(
      code: json['Code'] as String?,
      description: json['Description'] as String?,
      addDetails: json['AddDetails'] as AddDetails?,
      data: _dataFromJson(json, M),
    );
  }

  static I _dataFromJson<I>(Map<String, dynamic> json, Type type) {
    if (type == PublicPayResponse) {
      return PublicPayResponse.fromJson(json) as I;
    }
    return json as I;
  }

  Map<String, dynamic> toJson() {
    return _dataToJson(data);
  }

  dynamic _dataToJson<I>(I data) {
    if (data is PublicPayResponse) {
      return data.toJson();
    }

    return data;
  }
}

class AddDetails {
  final String orderId;
  final String transactionId;

  AddDetails({required this.orderId, required this.transactionId});

  factory AddDetails.fromJson(Map<String, dynamic> json) {
    return AddDetails(
      orderId: json['OrderId'] ?? '',
      transactionId: json['TransactionId'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'OrderId': orderId,
      'TransactionId': transactionId,
    };
  }
}
