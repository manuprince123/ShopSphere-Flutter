import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/data/auth_repository_impl.dart';
import '../../features/auth/data/token_store.dart';
import '../../features/auth/domain/auth.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/cart/data/cart_repository_impl.dart';
import '../../features/cart/domain/cart.dart';
import '../../features/cart/presentation/cart_controller.dart';
import '../../features/products/data/product_repository_impl.dart';
import '../../features/products/domain/product_repository.dart';
import '../../features/products/presentation/catalog_controller.dart';
import '../../features/products/presentation/product_controller.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/profile_repository.dart';
import '../../features/profile/presentation/profile_controller.dart';
import '../network/api_client.dart';

final sl = GetIt.instance;

Future<void> configureDependencies() async {
  final preferences = await SharedPreferences.getInstance();
  sl.registerSingleton<TokenStore>(SecureTokenStore(const FlutterSecureStorage()));
  sl.registerSingleton<ApiClient>(ApiClient(sl<TokenStore>(),
      onSessionExpired: () => sl<AuthController>().sessionExpired()));
  sl.registerSingleton<AuthRepository>(AuthRepositoryImpl(sl<ApiClient>().dio, sl<TokenStore>()));
  sl.registerSingleton<ProfileRepository>(ProfileRepositoryImpl(sl<ApiClient>().dio));
  sl.registerSingleton<ProductRepository>(ProductRepositoryImpl(sl<ApiClient>().dio));
  sl.registerSingleton<CartRepository>(CartRepositoryImpl(preferences, sl<ApiClient>().dio));
  sl.registerSingleton<CartController>(CartController(sl<CartRepository>(), const CalculateCartTotals()));
  sl.registerSingleton<AuthController>(AuthController(sl<AuthRepository>(),
      Login(sl<AuthRepository>()), sl<ProfileRepository>(),
      onSessionCleared: () => sl<CartController>().clear()));
  sl.registerFactory<CatalogController>(() => CatalogController(
      sl<ProductRepository>(), GetProducts(sl<ProductRepository>())));
  sl.registerFactory<ProductController>(() => ProductController(GetProduct(sl<ProductRepository>())));
  sl.registerFactory<ProfileController>(() => ProfileController(sl<ProfileRepository>()));
}
