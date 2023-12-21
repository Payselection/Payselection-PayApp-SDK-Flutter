# PaySelection SDK for Flutter

PaySelection SDK позволяет интегрировать прием платежей в мобильные приложение для кроссплатформенных приложений, написанных с помощью Flutter.

## Подключение
В pubspec.yaml уровня проекта добавить зависимость

```
dependencies: 
  payselection_sdk:
     git:
       url: https://github.com/Payselection/Payselection-PayApp-SDK-Flutter.git
       ref: //version
```


### Полезные ссылки

[Личный кабинет](https://merchant.payselection.com/login/)

[Разработчикам](https://api.payselection.com/#section/Request-signature)

### Структура проекта:

* **example** - Пример вызова методов с использованием SDK
* **lib** - Исходный код SDK


### Возможности PaySelection SDK:

Вы можете с помощью SDK:

* создать заказ и совершить платеж картой
* получить детализацию по конкретной транзации


### Инициализация PaySelection SDK:

1.	Создайте конфигурацию с данными из личного кабинета

```
final config = PaySelectionConfig.credential(
        publicKey:
            '04bd07d3547bd1f90ddbd985feaaec59420cabd082ff5215f34fd1c89c5d8562e8f5e97a5df87d7c99bc6f16a946319f61f9eb3ef7cf355d62469edb96c8bea09e', // Публичный ключ
        xSiteId: '21044' // Site ID
)
```

2.	Создайте экземпляр PaySelectionPaymentsSdk для работы с API

```
final sdk = PaySelectionSDK(config)
```

### Оплата с использованием PaySelection SDK:

1. Создайте объект PublicPayRequest с информацией о транзакции и данными карты

```
var request = PublicPayRequest(
      orderId: "SAM_SDK_3",
      description: "test payment",
      paymentMethod: PaymentMethod.cryptogram,
      amount: '10',
      currency: 'RUB',
      cardDetails:  CardDetails(
          cardHolderName: "TEST CARD",
          cardNumber: "5260111696757102", //success card
          //     cardNumber: '2408684917843810',     //fail card
          cvc: "123",
          expMonth: "12",
          expYear: "24"),
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
          ip: '8.8.8.8'),
      rebillFlag: false,
);
```

2. Асинхронно вызовите метод pay
   
   Отобразите WebView с полученной ссылкой на веб-интерфейс платежной системы (параметр "redirectUrl" из ответа сервера на метод "_pay") с помощью
   ThreeDS.

```
Future<BaseResponse<PublicPayResponse>> _pay() async {
    final response = await config.pay(request);

    return response;
}

_pay().proceedResult((responseData) {
      showDialog(
          context: context,
          builder: (builder) => ThreeDS(
            url: responseData.redirectUrl ?? '',
          )
     ).then((value) => ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(
          content: Text(value == true
              ? 'Success transaction'
              : 'Fail transaction'))));

      //for check transaction status use config.transactionStatus

      // config.transactionStatus(TransactionStatusRequest(
      //     transactionId: responseData.transactionId ?? "",
      //     transactionSecretKey:
      //     responseData.transactionSecretKey ?? ""));


  },
     (errorCode) => ScaffoldMessenger.of(context)
             .showSnackBar(SnackBar(content: Text(errorCode))));
  }
```

### Другие методы PaySelection SDK:

1. Получение статуса одной транзакции

```
config.transactionStatus(
    TransactionStatusRequest(
      transactionId,
      ransactionSecretKey
    )
  )
```

### Поддержка

По возникающим вопросам техничечкого характера обращайтесь на support@payselection.com
