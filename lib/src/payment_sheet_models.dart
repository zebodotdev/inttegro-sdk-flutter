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

final class PaymentSheetConfiguration {
  const PaymentSheetConfiguration({
    required this.orderId,
    this.returnUrl,
    this.appearance = const PaymentSheetAppearance(),
    this.telemetry = const PaymentSheetTelemetry(),
  });

  final String orderId;
  final Uri? returnUrl;
  final PaymentSheetAppearance appearance;
  final PaymentSheetTelemetry telemetry;

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
    return {
      'orderId': normalizedOrderId,
      if (returnUrl case final value?) 'returnURL': value.toString(),
      if (appearanceJson.isNotEmpty) 'appearance': appearanceJson,
      if (telemetryJson.isNotEmpty) 'telemetry': telemetryJson,
    };
  }
}

const _paymentSheetTelemetryEventNames = {
  'inttegro.payment_sheet.presented',
  'inttegro.checkout.load.started',
  'inttegro.checkout.load.succeeded',
  'inttegro.checkout.load.failed',
  'inttegro.payment.attempt.started',
  'inttegro.payment.attempt.failed',
  'inttegro.payment.confirmation.required',
  'inttegro.payment.authorization.required',
  'inttegro.payment.status.polling',
  'inttegro.payment_sheet.completed',
  'inttegro.payment_sheet.canceled',
  'inttegro.payment_sheet.failed',
  'inttegro.request.prepared',
  'inttegro.http.attempt.started',
  'inttegro.response.received',
  'inttegro.response.decoded',
  'inttegro.request.failed',
};

const _paymentSheetTelemetryOperations = {
  'checkout.lookup',
  'checkout.pay',
  'checkout.request_confirmation',
  'checkout.confirm_payment',
};

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
    final name = value['name'];
    final timestamp = value['timestamp'];
    final operation = value['operation'];
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
        name is! String ||
        !_paymentSheetTelemetryEventNames.contains(name) ||
        timestamp is! String ||
        DateTime.tryParse(timestamp) == null ||
        (operation != null &&
            (operation is! String ||
                !_paymentSheetTelemetryOperations.contains(operation))) ||
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
    return PaymentSheetTelemetryEvent(
      flowId: flowId,
      sequence: sequence,
      name: name,
      timestamp: DateTime.parse(timestamp),
      operation: operation as String?,
      httpStatusCode: httpStatusCode as int?,
      requestId: requestId as String?,
      errorType: errorType as String?,
    );
  }

  final String flowId;
  final int sequence;
  final String name;
  final DateTime timestamp;
  final String? operation;
  final int? httpStatusCode;
  final String? requestId;
  final String? errorType;
}

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

final class PaymentSheetCompleted extends PaymentSheetResult {
  const PaymentSheetCompleted({this.paymentId});

  final String? paymentId;
}

final class PaymentSheetCanceled extends PaymentSheetResult {
  const PaymentSheetCanceled();
}

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
