import 'package:flutter_test/flutter_test.dart';
import 'package:inttegro_flutter/inttegro_flutter.dart';

void main() {
  group('PaymentSheetConfiguration', () {
    test('normalizes its bridge payload', () {
      final value = PaymentSheetConfiguration(
        orderId: '  or_test  ',
        returnUrl: Uri.parse('merchant-app://inttegro-return'),
      ).toJson();

      expect(value['orderId'], 'or_test');
      expect(value['returnURL'], 'merchant-app://inttegro-return');
    });

    test('rejects invalid appearance values', () {
      expect(
        () => const PaymentSheetConfiguration(
          orderId: 'or_test',
          appearance: PaymentSheetAppearance(primaryColor: '#xyz'),
        ).toJson(),
        throwsArgumentError,
      );
    });

    test('validates W3C trace context', () {
      const traceparent =
          '00-4bf92f3577b34da6a3ce929d0e0e4736-00f067aa0ba902b7-01';
      final value = const PaymentSheetConfiguration(
        orderId: 'or_test',
        telemetry: PaymentSheetTelemetry(traceparent: traceparent),
      ).toJson();

      expect(
        (value['telemetry']! as Map<String, Object>)['traceparent'],
        traceparent,
      );
      expect(
        () => const PaymentSheetConfiguration(
          orderId: 'or_test',
          telemetry: PaymentSheetTelemetry(
            traceparent:
                '00-00000000000000000000000000000000-00f067aa0ba902b7-01',
          ),
        ).toJson(),
        throwsArgumentError,
      );
    });
  });

  test('decodes the shared result union', () {
    final result = PaymentSheetResult.fromJson({
      'status': 'failed',
      'error': {'code': 'declined', 'message': 'Payment declined'},
    });

    expect(result, isA<PaymentSheetFailed>());
    expect((result as PaymentSheetFailed).code, 'declined');
  });

  test('decodes privacy-safe telemetry events', () {
    final event = PaymentSheetTelemetryEvent.fromJson({
      'flowId': '550e8400-e29b-41d4-a716-446655440000',
      'sequence': 1,
      'name': 'inttegro.checkout.load.started',
      'timestamp': '2026-09-04T12:00:00.000Z',
    });

    expect(event.sequence, 1);
    expect(
      () => PaymentSheetTelemetryEvent.fromJson({
        'flowId': '550e8400-e29b-41d4-a716-446655440000',
        'sequence': 1,
        'name': 'inttegro.checkout.load.started',
        'timestamp': '2026-09-04T12:00:00.000Z',
        'orderId': 'or_private',
      }),
      throwsFormatException,
    );
  });
}
