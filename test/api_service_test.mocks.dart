import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';

/// Mock class for the `http.Client`.
class MockClient extends Mock implements http.Client {}

/// Mock Response Helper
class MockResponse extends Mock implements http.Response {
  @override
  int get statusCode => super.noSuchMethod(Invocation.getter(#statusCode), returnValue: 200) as int;

  @override
  String get body => super.noSuchMethod(Invocation.getter(#body), returnValue: '') as String;

  @override
  Map<String, String> get headers => super.noSuchMethod(Invocation.getter(#headers), returnValue: {}) as Map<String, String>;
}

/// Mocked response factory to easily create responses in your tests.
MockResponse createMockResponse({required int statusCode, required Map<String, dynamic> body}) {
  final response = MockResponse();
  when(response.statusCode).thenReturn(statusCode);
  when(response.body).thenReturn(jsonEncode(body));
  return response;
}

/// Helper for creating a list response.
MockResponse createMockListResponse({required int statusCode, required List<Map<String, dynamic>> body}) {
  final response = MockResponse();
  when(response.statusCode).thenReturn(statusCode);
  when(response.body).thenReturn(jsonEncode(body));
  return response;
}
