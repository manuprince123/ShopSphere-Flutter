import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [Locale('en'), Locale('hi')];

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations) ??
      const AppLocalizations(Locale('en'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String t(String key) =>
      (_values[locale.languageCode] ?? _values['en']!)[key] ??
      _values['en']![key] ??
      key;

  String productCount(int count) =>
      locale.languageCode == 'hi' ? '$count उत्पाद' : '$count products';

  String inStock(int count) =>
      locale.languageCode == 'hi' ? '$count स्टॉक में' : '$count in stock';

  static const _values = <String, Map<String, String>>{
    'en': {
      'appName': 'ShopSphere',
      'goodThings': 'Good things await.',
      'signInSubtitle': 'Sign in to explore your next favourite find.',
      'username': 'Username',
      'password': 'Password',
      'hidePassword': 'Hide password',
      'showPassword': 'Show password',
      'usernameValidation': 'Enter at least 3 characters',
      'passwordValidation': 'Enter at least 6 characters',
      'signIn': 'Sign in',
      'demoAccess': 'Demo access  ·  emilys / emilyspass',
      'explore': 'Explore',
      'saved': 'Saved',
      'cart': 'Cart',
      'profile': 'Profile',
      'discover': 'Discover your next find',
      'searchProducts': 'Search products',
      'clearSearch': 'Clear search',
      'all': 'All',
      'retryCategories': 'Retry categories',
      'curated': 'Curated for you',
      'sortProducts': 'Sort products',
      'featured': 'Featured',
      'priceLow': 'Price: low to high',
      'priceHigh': 'Price: high to low',
      'topRated': 'Top rated',
      'titleSort': 'Title: A to Z',
      'noProducts': 'No products found',
      'trySearch': 'Try another search or category.',
      'offlineBanner': 'You are offline — showing saved products.',
      'retry': 'Retry',
      'productDetails': 'Product details',
      'productNotFound': 'Product not found',
      'couldNotLoadProduct': 'Could not load product',
      'reviews': 'reviews',
      'outOfStock': 'Out of stock',
      'aboutItem': 'About this item',
      'decreaseQuantity': 'Decrease quantity',
      'increaseQuantity': 'Increase quantity',
      'addToCart': 'Add to cart',
      'customerReviews': 'Customer reviews',
      'noReviews': 'No reviews yet.',
      'yourBag': 'Your bag',
      'emptyBag': 'Your bag is empty',
      'emptyBagMessage': 'Find something you love in Explore.',
      'removeItem': 'Remove item',
      'subtotal': 'Subtotal',
      'discount': 'Discount',
      'grandTotal': 'Grand total',
      'placeOrder': 'Place order',
      'orderConfirmation': 'Order confirmation',
      'orderPlaced': 'Order placed!',
      'continueShopping': 'Continue shopping',
      'yourProfile': 'Your profile',
      'email': 'Email',
      'phone': 'Phone',
      'appearance': 'Appearance and language',
      'darkMode': 'Dark mode',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
      'signOut': 'Sign out',
      'savedItems': 'Saved items',
      'emptyWishlist': 'Nothing saved yet',
      'emptyWishlistMessage': 'Tap the heart on a product to save it here.',
      'removeSaved': 'Remove from saved items',
      'saveItem': 'Save item',
      'selectProduct': 'Select a product to see details',
      'retryLoadingMore': 'Retry loading more',
    },
    'hi': {
      'appName': 'शॉपस्फीयर',
      'goodThings': 'अच्छी चीज़ें आपका इंतज़ार कर रही हैं।',
      'signInSubtitle': 'अपनी पसंदीदा चीज़ें खोजने के लिए साइन इन करें।',
      'username': 'उपयोगकर्ता नाम',
      'password': 'पासवर्ड',
      'hidePassword': 'पासवर्ड छिपाएँ',
      'showPassword': 'पासवर्ड दिखाएँ',
      'usernameValidation': 'कम से कम 3 अक्षर दर्ज करें',
      'passwordValidation': 'कम से कम 6 अक्षर दर्ज करें',
      'signIn': 'साइन इन',
      'demoAccess': 'डेमो  ·  emilys / emilyspass',
      'explore': 'खोजें',
      'saved': 'सहेजे गए',
      'cart': 'कार्ट',
      'profile': 'प्रोफ़ाइल',
      'discover': 'अपनी अगली पसंद खोजें',
      'searchProducts': 'उत्पाद खोजें',
      'clearSearch': 'खोज साफ़ करें',
      'all': 'सभी',
      'retryCategories': 'श्रेणियाँ फिर लोड करें',
      'curated': 'आपके लिए चुना गया',
      'sortProducts': 'उत्पाद क्रमबद्ध करें',
      'featured': 'विशेष',
      'priceLow': 'कीमत: कम से अधिक',
      'priceHigh': 'कीमत: अधिक से कम',
      'topRated': 'सर्वोच्च रेटिंग',
      'titleSort': 'नाम: अ से ज्ञ',
      'noProducts': 'कोई उत्पाद नहीं मिला',
      'trySearch': 'दूसरी खोज या श्रेणी आज़माएँ।',
      'offlineBanner': 'आप ऑफ़लाइन हैं — सहेजे गए उत्पाद दिख रहे हैं।',
      'retry': 'फिर प्रयास करें',
      'productDetails': 'उत्पाद विवरण',
      'productNotFound': 'उत्पाद नहीं मिला',
      'couldNotLoadProduct': 'उत्पाद लोड नहीं हुआ',
      'reviews': 'समीक्षाएँ',
      'outOfStock': 'स्टॉक में नहीं',
      'aboutItem': 'इस उत्पाद के बारे में',
      'decreaseQuantity': 'मात्रा घटाएँ',
      'increaseQuantity': 'मात्रा बढ़ाएँ',
      'addToCart': 'कार्ट में जोड़ें',
      'customerReviews': 'ग्राहक समीक्षाएँ',
      'noReviews': 'अभी कोई समीक्षा नहीं।',
      'yourBag': 'आपका कार्ट',
      'emptyBag': 'आपका कार्ट खाली है',
      'emptyBagMessage': 'खोजें में अपनी पसंद की चीज़ चुनें।',
      'removeItem': 'उत्पाद हटाएँ',
      'subtotal': 'उप-योग',
      'discount': 'छूट',
      'grandTotal': 'कुल योग',
      'placeOrder': 'ऑर्डर करें',
      'orderConfirmation': 'ऑर्डर पुष्टि',
      'orderPlaced': 'ऑर्डर हो गया!',
      'continueShopping': 'खरीदारी जारी रखें',
      'yourProfile': 'आपकी प्रोफ़ाइल',
      'email': 'ईमेल',
      'phone': 'फ़ोन',
      'appearance': 'दिखावट और भाषा',
      'darkMode': 'डार्क मोड',
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिन्दी',
      'signOut': 'साइन आउट',
      'savedItems': 'सहेजे गए उत्पाद',
      'emptyWishlist': 'अभी कुछ सहेजा नहीं है',
      'emptyWishlistMessage': 'उत्पाद को यहाँ सहेजने के लिए दिल दबाएँ।',
      'removeSaved': 'सहेजे गए उत्पादों से हटाएँ',
      'saveItem': 'उत्पाद सहेजें',
      'selectProduct': 'विवरण देखने के लिए उत्पाद चुनें',
      'retryLoadingMore': 'और उत्पाद फिर लोड करें',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.supportedLocales.any(
    (supported) => supported.languageCode == locale.languageCode,
  );

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
