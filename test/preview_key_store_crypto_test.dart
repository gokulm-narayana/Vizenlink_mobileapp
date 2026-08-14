import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// Verifies the DER-encoding/round-trip logic `PreviewKeyStore` uses,
/// independent of `flutter_secure_storage` (which needs platform channels
/// this test doesn't set up) — exercises the same key generation, storage
/// serialization (hex round-trip), and DER public-key encoding, then proves
/// the encoded public key is both a valid parseable X.509
/// SubjectPublicKeyInfo structure and actually usable for the exact
/// RSA-OAEP-SHA256 wrap/unwrap `WanPreviewSnapshotClient` performs.
AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _generateKeyPair() {
  final secureRandom = FortunaRandom();
  final seedSource = Random.secure();
  final seed = Uint8List.fromList([
    for (var i = 0; i < 32; i++) seedSource.nextInt(256),
  ]);
  secureRandom.seed(KeyParameter(seed));

  final keyGen = RSAKeyGenerator()
    ..init(
      ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.from(65537), 2048, 64),
        secureRandom,
      ),
    );
  final pair = keyGen.generateKeyPair();
  return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
    pair.publicKey as RSAPublicKey,
    pair.privateKey as RSAPrivateKey,
  );
}

Uint8List _encodePublicKeyDer(RSAPublicKey publicKey) {
  final rsaPublicKeySeq = ASN1Sequence()
    ..add(ASN1Integer(publicKey.modulus))
    ..add(ASN1Integer(publicKey.exponent));
  final rsaPublicKeyBytes = rsaPublicKeySeq.encode();

  final algorithmSeq = ASN1Sequence()
    ..add(ASN1ObjectIdentifier.fromIdentifierString('1.2.840.113549.1.1.1'))
    ..add(ASN1Null());

  final publicKeyBitString = ASN1BitString(stringValues: rsaPublicKeyBytes);

  final topSeq = ASN1Sequence()
    ..add(algorithmSeq)
    ..add(publicKeyBitString);
  return topSeq.encode();
}

void main() {
  test('generated keypair round-trips through hex storage', () {
    final pair = _generateKeyPair();
    final private = pair.privateKey;

    // Same serialization PreviewKeyStore._storeKeyPair/_readStoredKeyPair use.
    final modulusHex = private.modulus!.toRadixString(16);
    final publicExponentHex = pair.publicKey.exponent!.toRadixString(16);
    final privateExponentHex = private.privateExponent!.toRadixString(16);
    final pHex = private.p!.toRadixString(16);
    final qHex = private.q!.toRadixString(16);

    BigInt parse(String hex) => BigInt.parse(hex, radix: 16);
    final restoredPrivate = RSAPrivateKey(
      parse(modulusHex),
      parse(privateExponentHex),
      parse(pHex),
      parse(qHex),
    );
    final restoredPublic = RSAPublicKey(
      parse(modulusHex),
      parse(publicExponentHex),
    );

    expect(restoredPrivate.modulus, private.modulus);
    expect(restoredPrivate.privateExponent, private.privateExponent);
    expect(restoredPublic.modulus, pair.publicKey.modulus);
    expect(restoredPublic.exponent, pair.publicKey.exponent);
  });

  test(
    'DER-encoded public key parses back to an equivalent SubjectPublicKeyInfo',
    () {
      final pair = _generateKeyPair();
      final der = _encodePublicKeyDer(pair.publicKey);

      // Parse it back the way a generic X.509 SPKI consumer would: outer
      // SEQUENCE { AlgorithmIdentifier SEQUENCE, BIT STRING }.
      final parser = ASN1Parser(der);
      final topSeq = parser.nextObject() as ASN1Sequence;
      expect(topSeq.elements!.length, 2);

      final algorithmSeq = topSeq.elements![0] as ASN1Sequence;
      final oid = algorithmSeq.elements![0] as ASN1ObjectIdentifier;
      expect(oid.objectIdentifierAsString, '1.2.840.113549.1.1.1');

      final bitString = topSeq.elements![1] as ASN1BitString;
      // First byte of a BIT STRING's raw encoding is the "unused bits"
      // count (0 here) followed by the actual PKCS#1 RSAPublicKey DER.
      final innerBytes = Uint8List.fromList(bitString.valueBytes!.sublist(1));
      final innerParser = ASN1Parser(innerBytes);
      final innerSeq = innerParser.nextObject() as ASN1Sequence;
      final modulus = (innerSeq.elements![0] as ASN1Integer).integer;
      final exponent = (innerSeq.elements![1] as ASN1Integer).integer;

      expect(modulus, pair.publicKey.modulus);
      expect(exponent, pair.publicKey.exponent);
    },
  );

  test(
    'RSA-OAEP-SHA256 wrap/unwrap round-trips (matches WanPreviewSnapshotClient)',
    () {
      final pair = _generateKeyPair();

      // Wrap — mirrors what camera firmware does with the registered
      // public key.
      final wrapCipher = OAEPEncoding.withSHA256(RSAEngine())
        ..init(true, PublicKeyParameter<RSAPublicKey>(pair.publicKey));
      final secret = Uint8List.fromList(List.generate(32, (i) => i));
      final wrapped = wrapCipher.process(secret);

      // Unwrap — exact code path WanPreviewSnapshotClient._unwrapContentKey
      // uses.
      final unwrapCipher = OAEPEncoding.withSHA256(RSAEngine())
        ..init(false, PrivateKeyParameter<RSAPrivateKey>(pair.privateKey));
      final unwrapped = unwrapCipher.process(wrapped);

      expect(unwrapped, secret);
    },
  );
}
