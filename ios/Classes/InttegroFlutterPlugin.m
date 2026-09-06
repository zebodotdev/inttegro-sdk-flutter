#import "InttegroFlutterPlugin.h"

#import <Inttegro/Inttegro-Swift.h>

static NSString *const InttegroChannelName = @"com.inttegro/sdk";
static NSString *const InttegroEventChannelName = @"com.inttegro/sdk/events";
static UIViewController *_Nullable InttegroTopViewController(
  UIViewController *_Nullable controller
);

@implementation InttegroFlutterPlugin {
  InttegroPaymentSheetCoordinator *_coordinator;
  __weak UIViewController *_viewController;
  FlutterEventSink _eventSink;
}

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar
{
  FlutterMethodChannel *channel = [FlutterMethodChannel
    methodChannelWithName:InttegroChannelName
          binaryMessenger:registrar.messenger];
  InttegroFlutterPlugin *instance = [[InttegroFlutterPlugin alloc]
    initWithViewController:registrar.viewController];
  [registrar addMethodCallDelegate:instance channel:channel];
  FlutterEventChannel *eventChannel = [FlutterEventChannel
    eventChannelWithName:InttegroEventChannelName
         binaryMessenger:registrar.messenger];
  [eventChannel setStreamHandler:instance];
}

- (instancetype)initWithViewController:(UIViewController *)viewController
{
  self = [super init];
  if (self) {
    _coordinator = [[InttegroPaymentSheetCoordinator alloc] init];
    _viewController = viewController;
    __weak InttegroFlutterPlugin *weakSelf = self;
    [_coordinator setTelemetryEventHandler:^(NSDictionary *event) {
      dispatch_async(dispatch_get_main_queue(), ^{
        InttegroFlutterPlugin *strongSelf = weakSelf;
        if (strongSelf != nil && strongSelf->_eventSink != nil) {
          strongSelf->_eventSink(event);
        }
      });
    }];
  }
  return self;
}

- (void)handleMethodCall:(FlutterMethodCall *)call result:(FlutterResult)result
{
  if ([call.method isEqualToString:@"initializePaymentSheet"]) {
    if (![call.arguments isKindOfClass:[NSDictionary class]]) {
      result([FlutterError
        errorWithCode:@"invalid_configuration"
               message:@"The payment sheet configuration must be an object."
               details:nil]);
      return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
      [self->_coordinator
        initializePaymentSheet:(NSDictionary *)call.arguments
        completion:^(NSString *code, NSString *message) {
          if (code != nil) {
            result([FlutterError errorWithCode:code message:message details:nil]);
            return;
          }
          result(nil);
        }];
    });
    return;
  }

  if ([call.method isEqualToString:@"presentPaymentSheet"]) {
    dispatch_async(dispatch_get_main_queue(), ^{
      UIViewController *presenter = InttegroTopViewController(self->_viewController);
      if (presenter == nil) {
        result([FlutterError
          errorWithCode:@"presentation_unavailable"
                 message:@"The payment sheet needs an active Flutter screen."
                 details:nil]);
        return;
      }
      [self->_coordinator
        presentPaymentSheetFrom:presenter
        completion:^(NSDictionary *payload, NSString *code, NSString *message) {
          if (code != nil) {
            result([FlutterError errorWithCode:code message:message details:nil]);
            return;
          }
          result(payload);
        }];
    });
    return;
  }

  result(FlutterMethodNotImplemented);
}

- (FlutterError *)onListenWithArguments:(id)arguments
                              eventSink:(FlutterEventSink)events
{
  _eventSink = [events copy];
  return nil;
}

- (FlutterError *)onCancelWithArguments:(id)arguments
{
  _eventSink = nil;
  return nil;
}

static UIViewController *InttegroTopViewController(UIViewController *controller)
{
  if (controller == nil) {
    return nil;
  }
  if (controller.presentedViewController != nil) {
    return InttegroTopViewController(controller.presentedViewController);
  }
  if ([controller isKindOfClass:[UINavigationController class]]) {
    return InttegroTopViewController(
      ((UINavigationController *)controller).visibleViewController
    );
  }
  if ([controller isKindOfClass:[UITabBarController class]]) {
    return InttegroTopViewController(
      ((UITabBarController *)controller).selectedViewController
    );
  }
  return controller;
}

@end
