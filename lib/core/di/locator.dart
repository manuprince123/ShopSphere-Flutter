import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/auth_remote_data_source.dart';
import '../../features/auth/data/token_store.dart';
import '../../features/auth/domain/auth.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cart/data/cart_repository_impl.dart';
import '../../features/cart/data/cart_local_data_source.dart';
import '../../features/cart/data/cart_remote_data_source.dart';
import '../../features/cart/domain/cart.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../../features/products/data/product_repository_impl.dart';
import '../../features/products/data/product_local_data_source.dart';
import '../../features/products/data/product_remote_data_source.dart';
import '../../features/products/domain/product_repository.dart';
import '../../features/products/presentation/catalog_controller.dart';
import '../../features/products/presentation/product_controller.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/data/profile_remote_data_source.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../../features/settings/data/settings_local_data_source.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/app_settings.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/wishlist/data/wishlist_local_data_source.dart';
import '../../features/wishlist/data/wishlist_repository_impl.dart';
import '../../features/wishlist/domain/wishlist.dart';
import '../../features/wishlist/presentation/wishlist_controller.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();
  sl.registerSingleton<TokenStore>(
    SecureTokenStore(const FlutterSecureStorage()),
  );
  sl.registerSingleton<ApiClient>(
    ApiClient(
      sl<TokenStore>(),
      onSessionExpired: () => sl<AuthController>().sessionExpired(),
    ),
  );
  sl.registerSingleton<AuthRemoteDataSource>(
    DioAuthRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerSingleton<AuthRepository>(
    AuthRepositoryImpl(sl<AuthRemoteDataSource>(), sl<TokenStore>()),
  );
  sl.registerSingleton<ProfileRemoteDataSource>(
    DioProfileRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerSingleton<ProfileRepository>(
    ProfileRepositoryImpl(sl<ProfileRemoteDataSource>()),
  );
  sl.registerSingleton<ProductRemoteDataSource>(
    DioProductRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerSingleton<ProductLocalDataSource>(
    PreferencesProductLocalDataSource(preferences),
  );
  sl.registerSingleton<ProductRepository>(
    ProductRepositoryImpl(
      sl<ProductRemoteDataSource>(),
      sl<ProductLocalDataSource>(),
    ),
  );
  sl.registerSingleton<CartLocalDataSource>(
    PreferencesCartLocalDataSource(preferences),
  );
  sl.registerSingleton<CartRemoteDataSource>(
    DioCartRemoteDataSource(sl<ApiClient>().dio),
  );
  sl.registerSingleton<CartRepository>(
    CartRepositoryImpl(sl<CartLocalDataSource>(), sl<CartRemoteDataSource>()),
  );
  sl.registerSingleton<WishlistLocalDataSource>(
    PreferencesWishlistLocalDataSource(preferences),
  );
  sl.registerSingleton<WishlistRepository>(
    WishlistRepositoryImpl(sl<WishlistLocalDataSource>()),
  );
  sl.registerSingleton<AppSettingsRepository>(
    AppSettingsRepositoryImpl(PreferencesSettingsLocalDataSource(preferences)),
  );
  sl.registerSingleton<CartController>(
    CartController(
      LoadCart(sl<CartRepository>()),
      SaveCart(sl<CartRepository>()),
      PlaceOrder(sl<CartRepository>()),
      const CalculateCartTotals(),
    ),
  );
  sl.registerSingleton<WishlistController>(
    WishlistController(
      LoadWishlist(sl<WishlistRepository>()),
      SaveWishlist(sl<WishlistRepository>()),
    ),
  );
  sl.registerSingleton<SettingsController>(
    SettingsController(
      LoadAppSettings(sl<AppSettingsRepository>()),
      SaveThemePreference(sl<AppSettingsRepository>()),
      SaveLocalePreference(sl<AppSettingsRepository>()),
    ),
  );
  sl.registerSingleton<AuthController>(
    AuthController(
      CheckSession(sl<AuthRepository>()),
      Login(sl<AuthRepository>()),
      GetProfile(sl<ProfileRepository>()),
      Logout(sl<AuthRepository>()),
      onSessionCleared: () async {
        await Future.wait([
          sl<CartController>().clear(),
          sl<WishlistController>().clear(),
        ]);
      },
    ),
  );
  sl.registerFactory<CatalogController>(
    () => CatalogController(
      GetProducts(sl<ProductRepository>()),
      GetCategories(sl<ProductRepository>()),
    ),
  );
  sl.registerFactory<ProductController>(
    () => ProductController(GetProduct(sl<ProductRepository>())),
  );
  sl.registerFactory<ProfileController>(
    () => ProfileController(GetProfile(sl<ProfileRepository>())),
  );
  await sl<SettingsController>().initialize();
}
