import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:internet_connection_checker/internet_connection_checker.dart';

import '../features/login/data/datasources/user_remote_data_source.dart';
import '../features/login/data/repositories/user_repository_impl.dart';
import '../features/login/domain/repositories/user_repository.dart';
import '../features/login/domain/usecases/login_user.dart';
import '../features/login/domain/usecases/logout_user.dart';
import '../features/login/presentation/blocs/bloc.dart';
import '../features/login/presentation/pages/login_screen.dart';
import '../features/selection/presentation/pages/selection_screen.dart';
import '../features/summary/presentation/pages/record_list.dart';
import '../navigation_drawer.dart';
import 'app_bar.dart';
import 'network/network_info.dart';
import 'utils/utils.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  late final http.Client client;
  late final UserRemoteDataSource userRemoteDataSource;
  late final UserRepository userRepository;
  late final NetworkInfo networkInfo;
  late final InternetConnectionChecker connectionChecker;

  MyApp({super.key}) {
    client = http.Client();
    connectionChecker = InternetConnectionChecker();
    networkInfo = NetworkInfoImpl(connectionChecker);
    userRemoteDataSource = UserRemoteDataSourceImpl(client: client);
    userRepository = UserRepositoryImpl(
        remoteDataSource: userRemoteDataSource, networkInfo: networkInfo);
  }

  final ValueNotifier<String> appBarTitleNotifier = ValueNotifier('root');

  Widget _wrapWithScaffold(
      BuildContext context, Widget child, String appBarTitle) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        drawer: const MyDrawer(),
        appBar: CustomAppBar(initialTitle: appBarTitle),
        body: BlocListener<LoginBloc, LoginState>(
          listener: (context, state) {
            if (state is LogoutError) {
              showSnackbar(context, state.message);
            } else if (state is LoginError) {
              showSnackbar(context, state.message);
            } else if (state is LogoutSuccess) {
              Navigator.of(context).pushReplacementNamed('/login');
            }
          },
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LoginBloc>(
          create: (context) => LoginBloc(
            loginUser: LoginUser(userRepository),
            logoutUser: LogoutUser(userRepository),
            inputValidator: InputValidator(),
          ),
        ),
      ],
      child: AppBarProvider(
        titleNotifier: appBarTitleNotifier,
        child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          title: 'My App',
          initialRoute: '/login',
          routes: {
            '/login': (_) => _wrapWithScaffold(_, const LoginScreen(), ''),
            '/selection': (_) => _wrapWithScaffold(
                _, const SelectionScreen(), 'Partner Selection'),
            '/summary': (_) =>
                _wrapWithScaffold(_, const RecordListPage(), 'Summary'),
          },
        ),
      ),
    );
  }
}
