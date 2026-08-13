import 'package:xml/xml.dart';

/// Some ONVIF actions come back as HTTP 200 even when the SOAP body itself is
/// a `<Fault>` (e.g. an authorization or invalid-argument rejection) — the
/// HTTP status alone isn't a reliable success signal for this firmware.
/// Every ONVIF client's `_post` should check this on top of the status code
/// before returning `CameraSuccess`. Returns the fault's human-readable
/// reason text, or null if the body isn't a fault (the overwhelmingly common
/// case, so this is checked after the happy path rather than parsed
/// unconditionally).
String? soapFaultReason(String body) {
  try {
    final doc = XmlDocument.parse(body);
    if (doc.findAllElements('Fault', namespace: '*').isEmpty) return null;
    final reasonText = doc.findAllElements('Text', namespace: '*');
    return reasonText.isNotEmpty
        ? reasonText.first.innerText.trim()
        : 'SOAP fault (no reason given)';
  } on Exception {
    return null;
  }
}
