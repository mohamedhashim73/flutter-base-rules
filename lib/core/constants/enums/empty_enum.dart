import 'package:base/core/services/base/asset_service.dart';

enum EmptyType {
  cart;

  String get name {
    switch (this) {
      case EmptyType.cart:
        return 'ازاي السلة فاضية!';
    }
  }

  String? get description {
    switch (this) {
      case EmptyType.cart:
        return "اكتشفي العروض وضيفي اللي يناسبك ياست الكل!";
    }
  }

  String? get image {
    switch (this) {
      case EmptyType.cart:
        return Assets.emptyCart;
    }
  }
}
