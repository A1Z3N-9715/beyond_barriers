import 'package:flutter/material.dart';
import 'pages/loading.dart';
import 'package:bb/firebase_options.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SignXApp());
}

class SignXApp extends StatelessWidget {
  const SignXApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'beyond barriers',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
      ),
      home: const LoadingPage(),
    );
  }
}
