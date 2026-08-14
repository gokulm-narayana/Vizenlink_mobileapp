import 'package:camera_api/camera_api.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  setUp(() {
    NetworkInfoClient.debugClearCaches();
    NuraeyeClient.debugClearCaches();
  });

  test('getSerialNumber parses SerialNumber from a real-shaped GetDeviceInformationResponse', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetDeviceInformation'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetDeviceInformationResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl">'
          '<tds:Manufacturer>VizenLink</tds:Manufacturer>'
          '<tds:Model>VZL-CAM</tds:Model>'
          '<tds:FirmwareVersion>1.0.0</tds:FirmwareVersion>'
          '<tds:SerialNumber>VZL-CAM-000001</tds:SerialNumber>'
          '<tds:HardwareId>HW-VZL-DEV-A</tds:HardwareId>'
          '</tds:GetDeviceInformationResponse>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.getSerialNumber();

    expect(result, isA<CameraSuccess<String>>());
    expect((result as CameraSuccess<String>).value, 'VZL-CAM-000001');
  });

  test('getSerialNumber surfaces CameraFailure for a rejected (HTTP 401) request', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'wrong'),
      httpClient: MockClient((request) async => http.Response('Unauthorized', 401)),
    );

    final result = await client.getSerialNumber();

    expect(result, isA<CameraFailure<String>>());
  });

  test('setDeviceName surfaces CameraFailure for a SOAP Fault returned with HTTP 200', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        // This firmware doesn't always return a non-200 status for a SOAP fault (e.g. Media2
        // validation errors) -- a robust client must check the body regardless of status.
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<s:Fault>'
          '<s:Code><s:Value>s:Receiver</s:Value></s:Code>'
          '<s:Reason><s:Text xml:lang="en">Invalid argument value</s:Text></s:Reason>'
          '</s:Fault>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setDeviceName('New Name');

    expect(result, isA<CameraFailure<void>>());
    expect((result as CameraFailure<void>).reason, contains('Invalid argument value'));
  });

  test('getDeviceIdentity parses name and location from GetScopesResponse, URI-decoded', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetScopes'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetScopesResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">'
          '<tds:Scopes><tt:ScopeDef>Fixed</tt:ScopeDef><tt:ScopeItem>onvif://www.onvif.org/Profile/Streaming</tt:ScopeItem></tds:Scopes>'
          '<tds:Scopes><tt:ScopeDef>Configurable</tt:ScopeDef><tt:ScopeItem>onvif://www.onvif.org/name/Front%20Door</tt:ScopeItem></tds:Scopes>'
          '<tds:Scopes><tt:ScopeDef>Configurable</tt:ScopeDef><tt:ScopeItem>onvif://www.onvif.org/location/Living%20Room</tt:ScopeItem></tds:Scopes>'
          '</tds:GetScopesResponse>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.getDeviceIdentity();

    expect(result, isA<CameraSuccess<DeviceIdentity>>());
    final identity = (result as CameraSuccess<DeviceIdentity>).value;
    expect(identity.name, 'Front Door');
    expect(identity.location, 'Living Room');
  });

  test('setDeviceName sends exactly one URI-encoded name Scopes entry', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('SetScopes'));
        expect(request.body, contains('onvif://www.onvif.org/name/Back%20Yard'));
        expect(request.body, isNot(contains('location')));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body><tds:SetScopesResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/></s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setDeviceName('Back Yard');

    expect(result, isA<CameraSuccess<void>>());
  });

  test('getSystemDateAndTime parses TZ, DST, and UTC date/time from the response', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetSystemDateAndTime'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetSystemDateAndTimeResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">'
          '<tds:SystemDateAndTime>'
          '<tt:DateTimeType>Manual</tt:DateTimeType>'
          '<tt:DaylightSavings>false</tt:DaylightSavings>'
          '<tt:TimeZone><tt:TZ>IST-5:30</tt:TZ></tt:TimeZone>'
          '<tt:UTCDateTime>'
          '<tt:Time><tt:Hour>10</tt:Hour><tt:Minute>30</tt:Minute><tt:Second>15</tt:Second></tt:Time>'
          '<tt:Date><tt:Year>2026</tt:Year><tt:Month>8</tt:Month><tt:Day>4</tt:Day></tt:Date>'
          '</tt:UTCDateTime>'
          '</tds:SystemDateAndTime>'
          '</tds:GetSystemDateAndTimeResponse>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.getSystemDateAndTime();

    expect(result, isA<CameraSuccess<DeviceDateTime>>());
    final dt = (result as CameraSuccess<DeviceDateTime>).value;
    expect(dt.timezone, 'IST-5:30');
    expect(dt.daylightSavings, false);
    expect(dt.year, 2026);
    expect(dt.month, 8);
    expect(dt.day, 4);
    expect(dt.hour, 10);
    expect(dt.minute, 30);
    expect(dt.second, 15);
  });

  test('setTimeZone re-reads the current UTC clock first, then echoes it back with the new TZ', () async {
    var requestCount = 0;
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          expect(request.body, contains('GetSystemDateAndTime'));
          return http.Response(
            '<?xml version="1.0" encoding="UTF-8"?>'
            '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
            '<s:Body>'
            '<tds:GetSystemDateAndTimeResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">'
            '<tds:SystemDateAndTime>'
            '<tt:DaylightSavings>false</tt:DaylightSavings>'
            '<tt:TimeZone><tt:TZ>UTC</tt:TZ></tt:TimeZone>'
            '<tt:UTCDateTime>'
            '<tt:Time><tt:Hour>10</tt:Hour><tt:Minute>30</tt:Minute><tt:Second>15</tt:Second></tt:Time>'
            '<tt:Date><tt:Year>2026</tt:Year><tt:Month>8</tt:Month><tt:Day>4</tt:Day></tt:Date>'
            '</tt:UTCDateTime>'
            '</tds:SystemDateAndTime>'
            '</tds:GetSystemDateAndTimeResponse>'
            '</s:Body>'
            '</s:Envelope>',
            200,
          );
        }
        expect(request.body, contains('SetSystemDateAndTime'));
        expect(request.body, contains('DateTimeType>Manual'));
        expect(request.body, contains('<tt:TZ>IST-5:30</tt:TZ>'));
        expect(request.body, contains('<tt:Hour>10</tt:Hour>'));
        expect(request.body, contains('<tt:Year>2026</tt:Year>'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body><tds:SetSystemDateAndTimeResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/></s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setTimeZone('IST-5:30');

    expect(result, isA<CameraSuccess<void>>());
    expect(requestCount, 2);
  });

  test('getDeviceInformation parses all five fields from GetDeviceInformationResponse', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetDeviceInformationResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl">'
          '<tds:Manufacturer>VizenLink</tds:Manufacturer>'
          '<tds:Model>VZL-CAM</tds:Model>'
          '<tds:FirmwareVersion>1.0.0</tds:FirmwareVersion>'
          '<tds:SerialNumber>VZL-CAM-000001</tds:SerialNumber>'
          '<tds:HardwareId>HW-VZL-DEV-A</tds:HardwareId>'
          '</tds:GetDeviceInformationResponse>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.getDeviceInformation();

    expect(result, isA<CameraSuccess<DeviceInformation>>());
    final info = (result as CameraSuccess<DeviceInformation>).value;
    expect(info.manufacturer, 'VizenLink');
    expect(info.model, 'VZL-CAM');
    expect(info.firmwareVersion, '1.0.0');
    expect(info.serialNumber, 'VZL-CAM-000001');
    expect(info.hardwareId, 'HW-VZL-DEV-A');
  });

  test('getNetworkInterfaceInfo parses interface name/MAC/IP and reports wireless correctly', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('GetNetworkInterfaces'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body>'
          '<tds:GetNetworkInterfacesResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl" xmlns:tt="http://www.onvif.org/ver10/schema">'
          '<tds:NetworkInterfaces token="eth0">'
          '<tt:Enabled>true</tt:Enabled>'
          '<tt:Info><tt:Name>wlan</tt:Name><tt:HwAddress>AA-BB-CC-DD-EE-FF</tt:HwAddress><tt:MTU>1500</tt:MTU></tt:Info>'
          '<tt:IPv4><tt:Enabled>true</tt:Enabled><tt:Config><tt:FromDHCP><tt:Address>192.168.1.50</tt:Address><tt:PrefixLength>24</tt:PrefixLength></tt:FromDHCP><tt:DHCP>true</tt:DHCP></tt:Config></tt:IPv4>'
          '</tds:NetworkInterfaces>'
          '</tds:GetNetworkInterfacesResponse>'
          '</s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.getNetworkInterfaceInfo();

    expect(result, isA<CameraSuccess<NetworkInterfaceInfo>>());
    final info = (result as CameraSuccess<NetworkInterfaceInfo>).value;
    expect(info.interfaceName, 'wlan');
    expect(info.macAddress, 'AA-BB-CC-DD-EE-FF');
    expect(info.ipv4Address, '192.168.1.50');
    expect(info.isWireless, true);
  });

  test('setUserPassword sends SetUser with username, password, and UserLevel Administrator', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('SetUser'));
        expect(request.body, contains('<tt:Username>admin</tt:Username>'));
        expect(request.body, contains('<tt:Password>newpw123</tt:Password>'));
        expect(request.body, contains('<tt:UserLevel>Administrator</tt:UserLevel>'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body><tds:SetUserResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/></s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setUserPassword('admin', 'newpw123');

    expect(result, isA<CameraSuccess<void>>());
  });

  test('setUserPassword XML-escapes special characters in the password', () async {
    final client = OnvifDeviceClient(
      const CameraConnection(host: '192.168.1.50', username: 'admin', password: 'pw'),
      httpClient: MockClient((request) async {
        expect(request.body, contains('<tt:Password>a&amp;b&lt;c&gt;d</tt:Password>'));
        return http.Response(
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<s:Envelope xmlns:s="http://www.w3.org/2003/05/soap-envelope">'
          '<s:Body><tds:SetUserResponse xmlns:tds="http://www.onvif.org/ver10/device/wsdl"/></s:Body>'
          '</s:Envelope>',
          200,
        );
      }),
    );

    final result = await client.setUserPassword('admin', 'a&b<c>d');

    expect(result, isA<CameraSuccess<void>>());
  });
}
