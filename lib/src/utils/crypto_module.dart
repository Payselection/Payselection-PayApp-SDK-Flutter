import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:encrypt/encrypt.dart' as encryptDart;
import 'package:pointycastle/export.dart' as pointycastle;

class Encryption {
  final pointycastle.ECCurve_secp256k1 _ecCurve = pointycastle.ECCurve_secp256k1();

  late final pointycastle.AsymmetricKeyPair _keyPair;
  late final pointycastle.ECDomainParameters _domainParameters;

  Uint8List randomIv(int blockSize) {
    final random = Random.secure();
    final iv = Uint8List(blockSize);
    for (var i = 0; i < blockSize; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  Uint8List? derivePublicKey(pointycastle.ECPrivateKey pKey) {
    final bigIntD = BigInt.parse(pKey.d.toString());
    final point = _ecCurve.G * bigIntD;
    return point?.getEncoded(false);
  }

  pointycastle.SecureRandom getSecureRandom() {
    var secureRandom = pointycastle.FortunaRandom();
    var random = Random.secure();
    List<int> seeds = [];
    for (int i = 0; i < 32; i++) {
      seeds.add(random.nextInt(255));
    }
    secureRandom.seed(pointycastle.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  Uint8List bigIntToUint8List(BigInt bigInt) {
    final byteData = ByteData((bigInt.bitLength / 8).ceil());
    var value = bigInt;

    for (var i = byteData.lengthInBytes - 1; i >= 0; i--) {
      byteData.setUint8(i, value.toUnsigned(8).toInt());
      value = value >> 8;
    }

    return byteData.buffer.asUint8List();
  }

  Uint8List deriveSharedKey(
      pointycastle.ECPrivateKey privateKey, pointycastle.ECPublicKey remotePublicKey) {
    final agreement = pointycastle.ECDHBasicAgreement();
    agreement.init(privateKey);
    final sharedKey = agreement.calculateAgreement(remotePublicKey);
    final digit2 = pointycastle.SHA512Digest().process(bigIntToUint8List(sharedKey));
    return Uint8List.fromList(digit2);
  }

  pointycastle.ECPrivateKey randomEphemeralKey() {
    var ecParams = pointycastle.ECKeyGeneratorParameters(_domainParameters);
    var params = pointycastle.ParametersWithRandom<pointycastle.ECKeyGeneratorParameters>(
        ecParams, getSecureRandom());
    var keyGenerator = pointycastle.ECKeyGenerator();
    keyGenerator.init(params);
    _keyPair = keyGenerator.generateKeyPair();
    return _keyPair.privateKey as pointycastle.ECPrivateKey;
  }

  pointycastle.ECPublicKey getPublicKey(String pKey) {
    _domainParameters = pointycastle.ECDomainParameters(_ecCurve.domainName);
    final point = _ecCurve.curve.decodePoint(hex.decode(pKey));
    return pointycastle.ECPublicKey(point, _domainParameters);
  }

  Uint8List hmacSha256(
      Uint8List hmacKey, Uint8List iv, Uint8List pKey, Uint8List data) {
    final hmac = pointycastle.HMac(pointycastle.SHA256Digest(), 64);
    final keyParam = pointycastle.KeyParameter(hmacKey);
    hmac.init(keyParam);
    var macData = iv + pKey + data;
    return hmac.process(Uint8List.fromList(macData));
  }

  EncryptedData encrypt(String data, String pKey) {
    final cbcCipher = pointycastle.CBCBlockCipher(pointycastle.AESEngine());
    final publicKey = getPublicKey(pKey);

    final ephemeralPrivateKey = randomEphemeralKey();
    final ephemeralPublicKey = derivePublicKey(ephemeralPrivateKey);
    final sharedKeyHash = deriveSharedKey(ephemeralPrivateKey, publicKey);
    final iv = randomIv(cbcCipher.blockSize);
    final paddingParams =
    pointycastle.PaddedBlockCipherParameters<pointycastle.ParametersWithIV<pointycastle.KeyParameter>, Null>(
      pointycastle.ParametersWithIV(pointycastle.KeyParameter(sharedKeyHash.sublist(0, 32)), iv),
      null,
    );
    final paddedCipher = pointycastle.PaddedBlockCipherImpl(pointycastle.PKCS7Padding(), cbcCipher)
      ..init(true, paddingParams);
    try {
      final encryptedData =
          paddedCipher.process(Uint8List.fromList(utf8.encode(data)));
      final mac = hmacSha256(sharedKeyHash.sublist(32, 64), iv,
          ephemeralPublicKey!, encryptedData);
      return EncryptedData(
          encrypted: encryptedData, key: ephemeralPublicKey, iv: iv, tag: mac);
    } catch (e) {
      print(e);
      return EncryptedData(
          encrypted: Uint8List(0),
          key: Uint8List(0),
          iv: Uint8List(0),
          tag: Uint8List(0));
    }
  }

  String createCryptogram(String paymentData, String publicKey) {
    final encryptedData = encrypt(paymentData, publicKey);
    final sendData = {
      'signedMessage': jsonEncode({
        'encryptedMessage': base64Encode(encryptedData.encrypted),
        'ephemeralPublicKey': base64Encode(encryptedData.key)
      }).toString(),
      'iv': base64Encode(encryptedData.iv),
      'tag': base64Encode(encryptedData.tag),
    };

    return base64Encode(jsonEncode(sendData).codeUnits);
  }

  String createCryptogramRsa(String paymentData, String key) {
    String pemString = utf8.decode(base64.decode(key));
    // Create RSA public key
    var keyParser = encryptDart.RSAKeyParser();
    pointycastle.RSAPublicKey publicKey =
        keyParser.parse(pemString) as pointycastle.RSAPublicKey;
    // Encrypt the data
    var encryptor = pointycastle.OAEPEncoding.withSHA256(pointycastle.RSAEngine())
      ..init(true, pointycastle.PublicKeyParameter<pointycastle.RSAPublicKey>(publicKey));

    return base64Encode(
      _processInBlocks(
        encryptor,
        Uint8List.fromList(paymentData.codeUnits),
      ),
    );
  }

  Uint8List _processInBlocks(pointycastle.AsymmetricBlockCipher engine, Uint8List input) {
    final numBlocks = input.length ~/ engine.inputBlockSize +
        ((input.length % engine.inputBlockSize != 0) ? 1 : 0);

    final output = Uint8List(numBlocks * engine.outputBlockSize);

    var inputOffset = 0;
    var outputOffset = 0;
    while (inputOffset < input.length) {
      final chunkSize = (inputOffset + engine.inputBlockSize <= input.length)
          ? engine.inputBlockSize
          : input.length - inputOffset;

      outputOffset += engine.processBlock(
          input, inputOffset, chunkSize, output, outputOffset);

      inputOffset += chunkSize;
    }

    return (output.length == outputOffset)
        ? output
        : output.sublist(0, outputOffset);
  }

}

class EncryptedData {
  final Uint8List encrypted;
  final Uint8List key;
  final Uint8List iv;
  final Uint8List tag;

  const EncryptedData(
      {required this.encrypted,
      required this.key,
      required this.iv,
      required this.tag});
}
