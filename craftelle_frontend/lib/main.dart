import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'login_page.dart';
import 'splash-screen.dart';



// Rose/Pink Elegance palette
const MaterialColor roseColor = MaterialColor(0xFFFDA4AF, <int, Color>{
  50: Color(0xFFFFF1F2),
  100: Color(0xFFFFE4E6),
  200: Color(0xFFFECDD3),
  300: Color(0xFFFDA4AF),
  400: Color(0xFFFB7185),
  500: Color(0xFFFDA4AF),
  600: Color(0xFFFDA4AF),
  700: Color(0xFFFB7185),
  800: Color(0xFFFB7185),
  900: Color(0xFFFECDD3),
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());

  // Use the FaceAuthApp for testing
  // runApp(const FaceAuthApp());
}

// Keep your original app code (commented out for now but preserved for later use)
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Craftelle',
      theme: ThemeData(
        primarySwatch: roseColor,
      ),
      home: AnimatedSplashScreen(
        nextScreen: LoginPage(),
        durationSeconds: 2,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

// Commented out options from original code:
//  home: const LoginPage(),
//  home : PregnancyComplicationsPage(),
// home: const LoginPage(),


