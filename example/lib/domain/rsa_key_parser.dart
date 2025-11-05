import 'dart:typed_data';

import 'package:pointycastle/export.dart' as pc;

/// Parse a BCRYPT_RSAPUBLIC_BLOB into RSAPublicKey
pc.RSAPublicKey parseBcryptRsaPublicKey(Uint8List blob) {
  final data = ByteData.sublistView(blob);

  final magic = data.getUint32(0, Endian.little);
  if (magic != 0x31415352) throw ArgumentError('Not RSA1 blob');

  final cbPubExp = data.getUint32(8, Endian.little);
  final cbModulus = data.getUint32(12, Endian.little);

  final expBytes = blob.sublist(16, 16 + cbPubExp);
  final exp = expBytes.fold<int>(0, (a, b) => (a << 8) | b);

  final modulusLE = blob.sublist(16 + cbPubExp, 16 + cbPubExp + cbModulus);
  final modulusBE = modulusLE.reversed.toList();

  return pc.RSAPublicKey(
    BigInt.parse(modulusBE.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16),
    BigInt.from(exp),
  );
}

/// Verify signature (PKCS#1 v1.5 + SHA256)
bool verifySignature(Uint8List message, Uint8List signature, pc.RSAPublicKey pubKey) {
  final verifier = pc.Signer('SHA-256/RSA');
  verifier.init(false, pc.PublicKeyParameter<pc.RSAPublicKey>(pubKey));
  return verifier.verifySignature(message, pc.RSASignature(signature));
}
