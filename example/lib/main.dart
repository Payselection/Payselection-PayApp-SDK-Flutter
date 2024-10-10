import 'package:flutter/material.dart';
import 'package:payselection_sdk/payselection.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'PaySelection-Flutter-SDK',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late PaySelectionSDK config;

  @override
  void initState() {
    super.initState();

    _pay().proceedResult(
      (responseData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Success transaction',
            ),
          ),
        );
        // showDialog(
        //     context: context,
        //     builder: (builder) => ThreeDS(
        //           url: responseData.redirectUrl ?? '',
        //         )).then(
        //   (value) => ScaffoldMessenger.of(context).showSnackBar(
        //     SnackBar(
        //       content: Text(
        //           value == true ? 'Success transaction' : 'Fail transaction'),
        //     ),
        //   ),
        // );

        // for check transaction status use config.transactionStatus
        //
        // config.transactionStatus(TransactionStatusRequest(
        //     transactionId: responseData.transactionId ?? "",
        //     transactionSecretKey:
        //     responseData.transactionSecretKey ?? ""));
      },
      (errorCode) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorCode),
        ),
      ),
    );
  }

  Future<BaseResponse<PublicPayResponse>> _pay() async {
    config = PaySelectionSDK(
      PaySelectionConfig.credential(
        publicKey:
            '04bd07d3547bd1f90ddbd985feaaec59420cabd082ff5215f34fd1c89c5d8562e8f5e97a5df87d7c99bc6f16a946319f61f9eb3ef7cf355d62469edb96c8bea09e',
        publicRsaKey:
            'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQ0lqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FnOEFNSUlDQ2dLQ0FnRUFxbk56eXlwR1R6cENZeDlzMnh6RQpaQ3B4eVkyL2YrbWljb0drWW1rV0M5Szl2SlIvcEtUL0VOUThCT1hIRkFBYW5Mb05PNzVLcmJUQ3Z5Y2pXbkJGCnhYQlJZY2NWeGsxaVB0c0VKbkNlcThmYXMwa2dYMFgzLzFnTFdvbkhheVdTUUl5emFTMXMrWUdsNEJyd2s5c08KTTQyZlk0dkM1WGptU1YxUDNlN2pvNUN1d2hxL2ljUkxZbTg1MXBYRTRiZ3FZYS96NEsrbXhUcWJvdC94b3lhTQpxSmlIOS9EUnQveTc0Z2t6Q0VIRThGQ0M4TkJlVXZUckRWbnlSQ0dtSlpVTDh0QnhPd1N3Ty94M1lzZi9CNU9vCkVjbllWdjVSQmF1MDl4VmFGTFN5QkZiRUsvZnRDUktFeUNQbnpYS2FnbTQ3T2dROEIvTkdhQ0cxRmdVOUhJb2gKd093TmsycWY1NTRPR21Oa0E3MnZCR1E0RTZ4TldUSnFJQWhOTUJQTjFMZGdRNXZTamszTUVJRHQ3Y3FEZzhFRwpCNU0vVS9VT2lVU2tXWmFtR3pXOVZFbkJhRFdWZFpxVVpTc0d0aCtJM093NGRPUUxiZG4rdzljYlpHLzR2VmwvCmFKdTdlQlZ2WVhEL0o0TnIzMk5RZ1o2YzlpMCtNU3RwWFUxMlJ4bzhJK1hCNVpZUTkzNE5iVXJoeDBuMlJhQk0KbGtlSTFtbE1ncWI3ME9BRk5zaDUyNUFIL3k5OVpJTzhsR0RqVEpSdDlKZzdGNVFmUEVWekRIbXdxdy9FaFFjQwpjVG5QaGRLOE53NDJ3QldIVDhXYXg4Y1NxYTdwRytTM2JOYkZvUVJlU1dvK2pzV0JNOU1NemJvckNqYWE1UzRNCnNCV0UyN2FRSElVMU5sTGNqK0laUldzQ0F3RUFBUT09Ci0tLS0tRU5EIFBVQkxJQyBLRVktLS0tLQo=',
        xSiteId: '21044',
        isDebug: true,
      ),
    );

    var request = PublicPayRequest(
      orderId: "SAM_SDK_3",
      description: "test payment",
      paymentMethod: PaymentMethod.externalForm,
      amount: '10',
      currency: 'RUB',
      // cardDetails: CardDetails(
      //   cardHolderName: "TEST CARD",
      //   cardNumber: "5260111696757102",
      //   //success card
      //   //     cardNumber: '2408684917843810',     //fail card
      //   cvc: "123",
      //   expMonth: "12",
      //   expYear: "24",
      // ),
      customerInfo: CustomerInfo(
        email: "user@example.com",
        phone: "+19991231212",
        language: "en",
        address: "string",
        town: "string",
        zip: "string",
        country: "USA",
        isSendReceipt: false,
        receiptEmail: 'paaa@mail.ru',
        ip: '8.8.8.8',
      ),
      rebillFlag: false,
    );

    final response = await config.pay(request);

    return response;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: FlutterLogo(
          size: 100,
        ),
      ),
    );
  }
}
