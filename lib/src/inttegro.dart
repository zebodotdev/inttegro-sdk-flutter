import 'package:flutter/services.dart';

import 'payment_sheet_models.dart';

final class Inttegro {
  Inttegro._();

  static final Inttegro instance = Inttegro._();

  static const MethodChannel _channel = MethodChannel('com.inttegro/sdk');
  static const EventChannel _eventChannel = EventChannel('com.inttegro/sdk/events');

  late final Stream<PaymentSheetTelemetryEvent> paymentSheetEvents =
      _eventChannel.receiveBroadcastStream().map((value) {
        if (value is! Map) {
          throw const FormatException(
            'Native payment sheet returned an invalid telemetry event',
          );
        }
        return PaymentSheetTelemetryEvent.fromJson(
          Map<Object?, Object?>.from(value),
        );
      });

  Future<void> initializePaymentSheet(
    PaymentSheetConfiguration configuration,
  ) async {
    await _channel.invokeMethod<void>(
      'initializePaymentSheet',
      configuration.toJson(),
    );
  }

  Future<PaymentSheetResult> presentPaymentSheet() async {
    final value = await _channel.invokeMapMethod<Object?, Object?>(
      'presentPaymentSheet',
    );
    if (value == null) {
      throw const FormatException('Native payment sheet returned no result');
    }
    return PaymentSheetResult.fromJson(value);
  }
}
