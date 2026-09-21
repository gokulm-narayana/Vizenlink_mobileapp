import 'package:xml/xml.dart';

/// Returns the SOAP fault reason text if [body] contains a `<Fault>` element, `null` otherwise.
///
/// **Why this exists:** every ONVIF client here used to only check the HTTP status code before
/// treating a response as success — but this firmware doesn't always return a non-200 status for
/// a SOAP fault. Media2 validation errors (e.g. `SetOSD` rejecting an out-of-range color via
/// `ter:InvalidArgVal`) come back as `HTTP 200` with a `<s:Fault>` body, which was silently
/// parsed as if it were the real response, hiding a real rejection from the caller. Every
/// `_post()`-style method must call this on the raw response body, after the HTTP-status check
/// and before attempting to parse the expected success shape — a robust SOAP client can never
/// rely on HTTP status alone to detect a fault.
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
