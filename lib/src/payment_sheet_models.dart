/// Optional visual overrides applied to the native payment sheet.
final class PaymentSheetAppearance {
  const PaymentSheetAppearance({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,
    this.cornerRadius,
  });

  final String? primaryColor;
  final String? backgroundColor;
  final String? textColor;
  final double? cornerRadius;

  Map<String, Object> toJson() {
    _validateColor('primaryColor', primaryColor);
    _validateColor('backgroundColor', backgroundColor);
    _validateColor('textColor', textColor);
    final radius = cornerRadius;
    if (radius != null && (!radius.isFinite || radius < 0 || radius > 40)) {
      throw ArgumentError.value(
        radius,
        'cornerRadius',
        'must be between 0 and 40',
      );
    }

    return {
      if (primaryColor case final value?) 'primaryColor': value,
      if (backgroundColor case final value?) 'backgroundColor': value,
      if (textColor case final value?) 'textColor': value,
      if (radius != null) 'cornerRadius': radius,
    };
  }

  static void _validateColor(String name, String? value) {
    if (value != null &&
        !RegExp(r'^#[0-9A-Fa-f]{6}([0-9A-Fa-f]{2})?$').hasMatch(value)) {
      throw ArgumentError.value(value, name, 'must be a 6 or 8 digit hex color');
    }
  }
}

/// Optional W3C trace context for application and SDK activity.
final class PaymentSheetTelemetry {
  const PaymentSheetTelemetry({
    this.enabled = true,
    this.traceparent,
    this.tracestate,
  });

  final bool enabled;
  final String? traceparent;
  final String? tracestate;

  Map<String, Object> toJson() {
    final parent = traceparent;
    if (parent != null &&
        !RegExp(
          r'^(?!ff)[0-9a-f]{2}-(?!0{32})[0-9a-f]{32}-(?!0{16})[0-9a-f]{16}-[0-9a-f]{2}$',
        )
            .hasMatch(parent)) {
      throw ArgumentError.value(
        parent,
        'traceparent',
        'must be a valid W3C trace parent',
      );
    }
    final state = tracestate;
    if (state != null &&
        (state.length > 512 || state.contains('\r') || state.contains('\n'))) {
      throw ArgumentError.value(
        state,
        'tracestate',
        'must be at most 512 characters without newlines',
      );
    }
    return {
      if (!enabled) 'enabled': false,
      if (parent != null) 'traceparent': parent,
      if (state != null) 'tracestate': state,
    };
  }
}

/// Optional content and actions exposed by the native payment sheet.
final class PaymentSheetFeatures {
  const PaymentSheetFeatures({
    this.showLineItems = false,
    this.showInvoiceDownload = false,
    this.showReceiptDownload = false,
    this.allowPaymentMethodChange = true,
  });

  /// Shows the Order's line items before payment. Defaults to `false`.
  final bool showLineItems;

  /// Offers the invoice after payment succeeds. Defaults to `false`.
  final bool showInvoiceDownload;

  /// Offers the receipt after payment succeeds. Defaults to `false`.
  final bool showReceiptDownload;

  /// Lets the payer replace an attached payment method. Defaults to `true`.
  final bool allowPaymentMethodChange;

  Map<String, Object> toJson() => {
        if (showLineItems) 'showLineItems': true,
        if (showInvoiceDownload) 'showInvoiceDownload': true,
        if (showReceiptDownload) 'showReceiptDownload': true,
        if (!allowPaymentMethodChange) 'allowPaymentMethodChange': false,
      };
}

/// Configuration stored for the next payment-sheet presentation.
final class PaymentSheetConfiguration {
  const PaymentSheetConfiguration({
    required this.orderId,
    this.returnUrl,
    this.appearance = const PaymentSheetAppearance(),
    this.telemetry = const PaymentSheetTelemetry(),
    this.features = const PaymentSheetFeatures(),
  });

  final String orderId;
  final Uri? returnUrl;
  final PaymentSheetAppearance appearance;
  final PaymentSheetTelemetry telemetry;
  /// Optional content and actions exposed by the native payment sheet.
  final PaymentSheetFeatures features;

  Map<String, Object> toJson() {
    final normalizedOrderId = orderId.trim();
    if (normalizedOrderId.isEmpty) {
      throw ArgumentError.value(
        orderId,
        'orderId',
        'must not be empty',
      );
    }
    if (returnUrl case final value? when !value.isAbsolute) {
      throw ArgumentError.value(value, 'returnUrl', 'must be an absolute URI');
    }

    final appearanceJson = appearance.toJson();
    final telemetryJson = telemetry.toJson();
    final featuresJson = features.toJson();
    return {
      'orderId': normalizedOrderId,
      if (returnUrl case final value?) 'returnURL': value.toString(),
      if (appearanceJson.isNotEmpty) 'appearance': appearanceJson,
      if (telemetryJson.isNotEmpty) 'telemetry': telemetryJson,
      if (featuresJson.isNotEmpty) 'features': featuresJson,
    };
  }
}

/// Stable wire names emitted by the native SDK diagnostic stream.
enum PaymentSheetTelemetryEventName {
  sheetPresented('inttegro.payment_sheet.presented'),
  checkoutLoadStarted('inttegro.checkout.load.started'),
  checkoutLoadSucceeded('inttegro.checkout.load.succeeded'),
  checkoutLoadFailed('inttegro.checkout.load.failed'),
  paymentAttemptStarted('inttegro.payment.attempt.started'),
  paymentAttemptFailed('inttegro.payment.attempt.failed'),
  confirmationRequired('inttegro.payment.confirmation.required'),
  authorizationRequired('inttegro.payment.authorization.required'),
  statusPolling('inttegro.payment.status.polling'),
  sheetCompleted('inttegro.payment_sheet.completed'),
  sheetCanceled('inttegro.payment_sheet.canceled'),
  sheetFailed('inttegro.payment_sheet.failed'),
  requestPrepared('inttegro.request.prepared'),
  httpAttemptStarted('inttegro.http.attempt.started'),
  responseReceived('inttegro.response.received'),
  responseDecoded('inttegro.response.decoded'),
  requestFailed('inttegro.request.failed');

  const PaymentSheetTelemetryEventName(this.wireValue);

  /// The exact name emitted across the platform channel.
  final String wireValue;

  static PaymentSheetTelemetryEventName? fromWireValue(String value) {
    for (final name in values) {
      if (name.wireValue == value) return name;
    }
    return null;
  }
}

/// Checkout operations that may appear in diagnostic events.
enum PaymentSheetTelemetryOperation {
  checkoutLookup('checkout.lookup'),
  checkoutPay('checkout.pay'),
  checkoutRequestConfirmation('checkout.request_confirmation'),
  checkoutConfirmPayment('checkout.confirm_payment');

  const PaymentSheetTelemetryOperation(this.wireValue);

  /// The exact operation name emitted across the platform channel.
  final String wireValue;

  static PaymentSheetTelemetryOperation? fromWireValue(String value) {
    for (final operation in values) {
      if (operation.wireValue == value) return operation;
    }
    return null;
  }
}

const _paymentSheetTelemetryEventFields = {
  'flowId',
  'sequence',
  'name',
  'timestamp',
  'operation',
  'httpStatusCode',
  'requestId',
  'errorType',
};

/// Privacy-safe diagnostic metadata from one payment-sheet presentation.
final class PaymentSheetTelemetryEvent {
  const PaymentSheetTelemetryEvent({
    required this.flowId,
    required this.sequence,
    required this.name,
    required this.timestamp,
    this.operation,
    this.httpStatusCode,
    this.requestId,
    this.errorType,
  });

  factory PaymentSheetTelemetryEvent.fromJson(Map<Object?, Object?> value) {
    final flowId = value['flowId'];
    final sequence = value['sequence'];
    final rawName = value['name'];
    final timestamp = value['timestamp'];
    final rawOperation = value['operation'];
    final httpStatusCode = value['httpStatusCode'];
    final requestId = value['requestId'];
    final errorType = value['errorType'];
    if (value.keys.any(
          (key) =>
              key is! String || !_paymentSheetTelemetryEventFields.contains(key),
        ) ||
        flowId is! String ||
        !RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        ).hasMatch(flowId) ||
        sequence is! int ||
        sequence < 1 ||
        rawName is! String ||
        timestamp is! String ||
        DateTime.tryParse(timestamp) == null ||
        (rawOperation != null && rawOperation is! String) ||
        (httpStatusCode != null &&
            (httpStatusCode is! int ||
                httpStatusCode < 100 ||
                httpStatusCode > 599)) ||
        (requestId != null &&
            (requestId is! String ||
                requestId.isEmpty ||
                requestId.length > 255)) ||
        (errorType != null &&
            (errorType is! String || errorType.isEmpty || errorType.length > 64))) {
      throw const FormatException(
        'Native payment sheet returned an invalid telemetry event',
      );
    }
    final name = PaymentSheetTelemetryEventName.fromWireValue(rawName);
    final operation = rawOperation == null
        ? null
        : PaymentSheetTelemetryOperation.fromWireValue(rawOperation as String);
    if (name == null || (rawOperation != null && operation == null)) {
      throw const FormatException(
        'Native payment sheet returned an unknown telemetry event',
      );
    }
    return PaymentSheetTelemetryEvent(
      flowId: flowId,
      sequence: sequence,
      name: name,
      timestamp: DateTime.parse(timestamp),
      operation: operation,
      httpStatusCode: httpStatusCode as int?,
      requestId: requestId as String?,
      errorType: errorType as String?,
    );
  }

  final String flowId;
  final int sequence;
  final PaymentSheetTelemetryEventName name;
  final DateTime timestamp;
  final PaymentSheetTelemetryOperation? operation;
  final int? httpStatusCode;
  final String? requestId;
  final String? errorType;
}

/// Application-facing payment-sheet lifecycle transitions.
enum PaymentSheetEventType {
  presented,
  checkoutLoadStarted,
  checkoutLoadSucceeded,
  checkoutLoadFailed,
  paymentAttemptStarted,
  paymentAttemptFailed,
  confirmationRequired,
  authorizationRequired,
  paymentStatusPolling,
  completed,
  canceled,
  failed,
}

/// An application-facing stage in one payment-sheet presentation.
///
/// Recoverable failures leave the native sheet open so the customer can retry.
/// Terminal application behavior belongs in the [PaymentSheetResult] returned
/// by `presentPaymentSheet`.
final class PaymentSheetEvent {
  const PaymentSheetEvent({
    required this.flowId,
    required this.sequence,
    required this.type,
    required this.timestamp,
    this.errorType,
  });

  final String flowId;
  final int sequence;
  final PaymentSheetEventType type;
  final DateTime timestamp;
  final String? errorType;

  /// Whether this event represents the end of the sheet presentation.
  bool get isTerminal => switch (type) {
    PaymentSheetEventType.completed ||
    PaymentSheetEventType.canceled ||
    PaymentSheetEventType.failed =>
      true,
    _ => false,
  };

  /// Whether the sheet remains open and permits the customer to retry.
  bool get isRecoverableFailure => switch (type) {
    PaymentSheetEventType.checkoutLoadFailed ||
    PaymentSheetEventType.paymentAttemptFailed =>
      true,
    _ => false,
  };
}

/// Terminal outcome of one native payment-sheet presentation.
sealed class PaymentSheetResult {
  const PaymentSheetResult();

  factory PaymentSheetResult.fromJson(Map<Object?, Object?> value) {
    switch (value['status']) {
      case 'completed':
        final paymentId = value['paymentId'];
        if (paymentId != null && paymentId is! String) {
          throw const FormatException('Invalid paymentId from native payment sheet');
        }
        return PaymentSheetCompleted(paymentId: paymentId as String?);
      case 'canceled':
        return const PaymentSheetCanceled();
      case 'failed':
        final error = value['error'];
        if (error is! Map) {
          throw const FormatException('Invalid error from native payment sheet');
        }
        final code = error['code'];
        final message = error['message'];
        final declineCode = error['declineCode'];
        if (code is! String ||
            message is! String ||
            (declineCode != null && declineCode is! String)) {
          throw const FormatException('Invalid error from native payment sheet');
        }
        return PaymentSheetFailed(
          code: code,
          message: message,
          declineCode: declineCode as String?,
        );
      default:
        throw const FormatException('Unknown result from native payment sheet');
    }
  }
}

/// The payment sheet completed its client-side payment flow.
///
/// The merchant backend must still verify the authoritative Order state before
/// fulfillment.
final class PaymentSheetCompleted extends PaymentSheetResult {
  const PaymentSheetCompleted({this.paymentId});

  final String? paymentId;
}

/// The customer dismissed the payment sheet before completion.
final class PaymentSheetCanceled extends PaymentSheetResult {
  const PaymentSheetCanceled();
}

/// The payment sheet stopped because of a terminal error.
final class PaymentSheetFailed extends PaymentSheetResult {
  const PaymentSheetFailed({
    required this.code,
    required this.message,
    this.declineCode,
  });

  final String code;
  final String message;
  final String? declineCode;
}
