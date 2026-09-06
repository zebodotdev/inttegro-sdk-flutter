# Inttegro Flutter

[API reference](https://flutter.inttegro.dev/v0.1.0/) ·
[Studio guide](https://studio.inttegro.com/sdks/flutter)

Typed Flutter facade for Inttegro's native payment sheet. This is an
implementation spike and is not ready to publish or use with live payments.
The current collection surface supports mobile money; card, Apple Pay, and
Google Pay are not exposed.

```dart
final telemetrySubscription = Inttegro.instance.paymentSheetEvents.listen(
  (event) {
    // Record this with your app-owned OpenTelemetry provider or logging sink.
    recordInttegroEvent(event);
  },
);

await Inttegro.instance.initializePaymentSheet(
  PaymentSheetConfiguration(
    orderId: orderId,
    returnUrl: Uri.parse('merchant-app://inttegro-return'),
    telemetry: activeTraceContext, // Optional traceparent and tracestate.
  ),
);

try {
  final result = await Inttegro.instance.presentPaymentSheet();
} finally {
  await telemetrySubscription.cancel();
}
```

The method channel maps directly to the shared native iOS and Android payment
artifacts. Those native implementations own presentation, accessibility,
authentication, payment collection, and lifecycle state; Dart only validates
the public input and decodes the result.

The event stream receives ordered, per-presentation lifecycle and Checkout
network events from native code. Inttegro does not install or own an exporter:
the host decides whether to translate them into spans, logs, or other
diagnostics. Events contain bounded status and correlation metadata, never
Order or Payment IDs, customer or payer data, payment-method details, request or
response bodies, redirect URLs, or raw error messages. `flowId` and `requestId`
should not be used as metric labels. Subscribe before presenting the sheet so
the first event is not missed.

The package registers an Android and iOS plugin for each Flutter engine. The
plugins keep presentation state isolated per engine and delegate to the same
native `Inttegro` artifacts used by the React Native SDK. CocoaPods links the
iOS artifact through `inttegro_flutter.podspec`, while Gradle resolves
`com.inttegro:inttegro-android:0.1.0`.

## Requirements

- Flutter 3.44 or later and Dart 3.12 or later
- iOS 16 or later
- Android API 26 or later

Add the package, fetch dependencies, and rebuild the application so Flutter can
register the native plugin. Hot reload alone cannot add a newly installed
native plugin to a running application.
