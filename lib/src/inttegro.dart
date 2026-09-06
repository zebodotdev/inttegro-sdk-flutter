import 'package:flutter/services.dart';

import 'payment_sheet_models.dart';

/// Entry point for configuring, presenting, and observing the payment sheet.
final class Inttegro {
  Inttegro._();

  /// The process-wide Flutter facade for the registered Inttegro plugin.
  static final Inttegro instance = Inttegro._();

  static const MethodChannel _channel = MethodChannel('com.inttegro/sdk');
  static const EventChannel _eventChannel = EventChannel('com.inttegro/sdk/events');

  /// Privacy-safe transport diagnostics for an application-owned telemetry
  /// pipeline. These events are not authoritative payment state.
  late final Stream<PaymentSheetTelemetryEvent> paymentSheetTelemetryEvents =
      _eventChannel.receiveBroadcastStream().map((value) {
        if (value is! Map) {
          throw const FormatException(
            'Native payment sheet returned an invalid telemetry event',
          );
        }
        return PaymentSheetTelemetryEvent.fromJson(
          Map<Object?, Object?>.from(value),
        );
      }).asBroadcastStream();

  /// Typed application-facing lifecycle events for the active payment sheet.
  ///
  /// Subscribe before presenting the sheet so the first event is not missed.
  late final Stream<PaymentSheetEvent> paymentSheetEvents =
      paymentSheetTelemetryEvents
          .map(_toPaymentSheetEvent)
          .where((event) => event != null)
          .cast<PaymentSheetEvent>();

  /// Validates and stores [configuration] for the next presentation.
  ///
  /// This method does not perform the Checkout network request.
  Future<void> initializePaymentSheet(
    PaymentSheetConfiguration configuration,
  ) async {
    await _channel.invokeMethod<void>(
      'initializePaymentSheet',
      configuration.toJson(),
    );
  }

  /// Opens the native payment sheet and returns its terminal result.
  ///
  /// Recoverable payment-attempt failures are handled inside the sheet and do
  /// not complete this future.
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

PaymentSheetEvent? _toPaymentSheetEvent(PaymentSheetTelemetryEvent event) {
  final type = switch (event.name) {
    PaymentSheetTelemetryEventName.sheetPresented =>
      PaymentSheetEventType.presented,
    PaymentSheetTelemetryEventName.checkoutLoadStarted =>
      PaymentSheetEventType.checkoutLoadStarted,
    PaymentSheetTelemetryEventName.checkoutLoadSucceeded =>
      PaymentSheetEventType.checkoutLoadSucceeded,
    PaymentSheetTelemetryEventName.checkoutLoadFailed =>
      PaymentSheetEventType.checkoutLoadFailed,
    PaymentSheetTelemetryEventName.paymentAttemptStarted =>
      PaymentSheetEventType.paymentAttemptStarted,
    PaymentSheetTelemetryEventName.paymentAttemptFailed =>
      PaymentSheetEventType.paymentAttemptFailed,
    PaymentSheetTelemetryEventName.confirmationRequired =>
      PaymentSheetEventType.confirmationRequired,
    PaymentSheetTelemetryEventName.authorizationRequired =>
      PaymentSheetEventType.authorizationRequired,
    PaymentSheetTelemetryEventName.statusPolling =>
      PaymentSheetEventType.paymentStatusPolling,
    PaymentSheetTelemetryEventName.sheetCompleted =>
      PaymentSheetEventType.completed,
    PaymentSheetTelemetryEventName.sheetCanceled =>
      PaymentSheetEventType.canceled,
    PaymentSheetTelemetryEventName.sheetFailed => PaymentSheetEventType.failed,
    PaymentSheetTelemetryEventName.requestPrepared ||
    PaymentSheetTelemetryEventName.httpAttemptStarted ||
    PaymentSheetTelemetryEventName.responseReceived ||
    PaymentSheetTelemetryEventName.responseDecoded ||
    PaymentSheetTelemetryEventName.requestFailed =>
      null,
  };
  if (type == null) return null;
  return PaymentSheetEvent(
    flowId: event.flowId,
    sequence: event.sequence,
    type: type,
    timestamp: event.timestamp,
    errorType: event.errorType,
  );
}
