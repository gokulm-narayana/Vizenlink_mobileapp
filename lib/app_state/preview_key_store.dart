import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';

/// One RSA-2048 keypair per device (not per camera) — backs
/// `WanAuth.previewPrivateKeyProvider`/`onPreviewKeyNeedsRegistration`
/// (`packages/camera_api/lib/src/wan/wan_auth.dart`), which
/// `WanPreviewSnapshotClient` uses to decrypt end-to-end-encrypted WAN
/// preview snapshots. The camera encrypts to whichever public key was last
/// registered with it (`RegisterPreviewKey`, LAN-only) — a single
/// device-wide keypair, registered with every camera this device pairs
/// with, matches how the camera side only ever tracks one registered key
/// per pairing.
///
/// **Registration wire format is a best-effort guess, not yet
/// hardware-verified**: `RegisterPreviewKey`'s `public_key` field has no
/// documented format in `packages/camera_api`. Sends a base64-encoded X.509
/// `SubjectPublicKeyInfo` DER structure — the standard format
/// `mbedtls_pk_parse_public_key` (the parser the camera's own encryption
/// side already uses, per `WanPreviewSnapshotClient`'s doc) accepts
/// directly, and the conventional choice absent a documented alternative.
/// If real-hardware registration is confirmed to expect a different shape
/// (raw PKCS#1, PEM-wrapped, etc.), only [_encodePublicKeyDer] needs to
/// change.
class PreviewKeyStore {
  PreviewKeyStore._();

  static final PreviewKeyStore instance = PreviewKeyStore._();

  final _storage = const FlutterSecureStorage();

  static const _modulusKey = 'preview_key_modulus';
  static const _publicExponentKey = 'preview_key_public_exponent';
  static const _privateExponentKey = 'preview_key_private_exponent';
  static const _pKey = 'preview_key_p';
  static const _qKey = 'preview_key_q';
  static const _registeredThingsKey = 'preview_key_registered_things';

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? _cachedPair;

  /// The stored private key, or null if no keypair has been generated on
  /// this device yet. Never generates one — see [_getOrCreateKeyPair] for
  /// the only path that does, gated on an actual LAN registration attempt
  /// so a key is never generated without also being registered somewhere.
  Future<RSAPrivateKey?> getExistingPrivateKey() async {
    final cached = _cachedPair;
    if (cached != null) return cached.privateKey;
    final stored = await _readStoredKeyPair();
    if (stored == null) return null;
    _cachedPair = stored;
    return stored.privateKey;
  }

  /// Base64 X.509 SubjectPublicKeyInfo DER for [RegisterPreviewKey] —
  /// generates and persists a fresh keypair first if this device doesn't
  /// have one yet.
  Future<String> getOrCreatePublicKeyBase64() async {
    final pair = await _getOrCreateKeyPair();
    return base64Encode(_encodePublicKeyDer(pair.publicKey));
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>>
  _getOrCreateKeyPair() async {
    final cached = _cachedPair;
    if (cached != null) return cached;
    final stored = await _readStoredKeyPair();
    if (stored != null) {
      _cachedPair = stored;
      return stored;
    }
    final generated = _generateKeyPair();
    await _storeKeyPair(generated);
    _cachedPair = generated;
    return generated;
  }

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

  Future<void> _storeKeyPair(
    AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> pair,
  ) async {
    final private = pair.privateKey;
    await Future.wait([
      _storage.write(
        key: _modulusKey,
        value: private.modulus!.toRadixString(16),
      ),
      _storage.write(
        key: _publicExponentKey,
        value: pair.publicKey.exponent!.toRadixString(16),
      ),
      _storage.write(
        key: _privateExponentKey,
        value: private.privateExponent!.toRadixString(16),
      ),
      _storage.write(key: _pKey, value: private.p!.toRadixString(16)),
      _storage.write(key: _qKey, value: private.q!.toRadixString(16)),
    ]);
  }

  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>?>
  _readStoredKeyPair() async {
    final values = await Future.wait([
      _storage.read(key: _modulusKey),
      _storage.read(key: _publicExponentKey),
      _storage.read(key: _privateExponentKey),
      _storage.read(key: _pKey),
      _storage.read(key: _qKey),
    ]);
    final modulusHex = values[0];
    final publicExponentHex = values[1];
    final privateExponentHex = values[2];
    final pHex = values[3];
    final qHex = values[4];
    if (modulusHex == null ||
        publicExponentHex == null ||
        privateExponentHex == null ||
        pHex == null ||
        qHex == null) {
      return null;
    }
    BigInt parse(String hex) => BigInt.parse(hex, radix: 16);
    final modulus = parse(modulusHex);
    final privateKey = RSAPrivateKey(
      modulus,
      parse(privateExponentHex),
      parse(pHex),
      parse(qHex),
    );
    final publicKey = RSAPublicKey(modulus, parse(publicExponentHex));
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      publicKey,
      privateKey,
    );
  }

  /// X.509 `SubjectPublicKeyInfo` DER encoding — see this class's doc
  /// comment for why this specific format was chosen.
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

  /// Whether this device's public key has already been registered with
  /// camera [thingName] — tracked locally so a LAN sync doesn't re-send
  /// `RegisterPreviewKey` on every single reachability check, only once per
  /// camera (or again after [flagNeedsReregistration]).
  Future<bool> isRegistered(String thingName) async {
    final registered = await _registeredThings();
    return registered.contains(thingName);
  }

  Future<void> markRegistered(String thingName) async {
    final registered = await _registeredThings();
    if (registered.add(thingName)) await _writeRegisteredThings(registered);
  }

  /// Called via `WanAuth.onPreviewKeyNeedsRegistration` when the camera
  /// reports it has no preview key registered (e.g. a factory reset wiped
  /// it) — clears the local "already registered" flag so the next LAN sync
  /// re-sends `RegisterPreviewKey` automatically instead of the camera
  /// silently failing every WAN preview request until the user notices and
  /// re-adds it manually.
  Future<void> flagNeedsReregistration(String thingName) async {
    final registered = await _registeredThings();
    if (registered.remove(thingName)) {
      await _writeRegisteredThings(registered);
    }
  }

  Future<Set<String>> _registeredThings() async {
    final raw = await _storage.read(key: _registeredThingsKey);
    if (raw == null || raw.isEmpty) return {};
    return (jsonDecode(raw) as List).cast<String>().toSet();
  }

  Future<void> _writeRegisteredThings(Set<String> things) =>
      _storage.write(key: _registeredThingsKey, value: jsonEncode([...things]));
}
