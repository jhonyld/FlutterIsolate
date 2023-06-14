import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Isolate Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<String> _imageUrls = [];
  bool _isLoading = false;
  bool _isComputing = false;
  String _result = '';

  @override
  void initState() {
    super.initState();
    loadImages();
  }

  void loadImages() async {
    setState(() {
      _isLoading = true;
    });

    const apiUrl = 'https://api.nasa.gov/planetary/apod?count=10&api_key=b3miF1oec0XG71KcRE2tbhuvWcnuaWBxood8Dvxi';

    final response = await http.get(Uri.parse(apiUrl));
    final List<dynamic> data = json.decode(response.body);
    final List<String> imageUrls = List<String>.from(data.map((item) => item['url']));

    setState(() {
      _imageUrls = imageUrls;
      _isLoading = false;
    });
  }

  ///USING ISOLATE - COMPUTE METHOD
  Future<void> executeComplexMath() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    const int n = 43; // Fibonacci number to calculate

    final stopwatch = Stopwatch()..start();
    final result = await compute(calculateFibonacci, n);
    stopwatch.stop();

    setState(() {
      _isComputing = false;
      _result = 'COMPUTE - Fibonacci($n) = $result (Elapsed time: ${stopwatch.elapsed.inSeconds}s)';
      _imageUrls = List<String>.from(_imageUrls.reversed);
    });
    print(_result);
  }

  static int calculateFibonacci(int n) {
    if (n == 0) return 0;
    if (n == 1) return 1;

    return calculateFibonacci(n - 1) + calculateFibonacci(n - 2);
  }

  ///USING ISOLATE - ISOLATE.SPAWN METHOD
  Future<void> executeComplexMathSpawn() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });
    ReceivePort port = ReceivePort();
    const int n = 43; // Fibonacci number to calculate

    final stopwatch = Stopwatch()..start();

    final isolate = await Isolate.spawn(calculateFibonacciSpawn, [port.sendPort, n]);
    final result = await port.first;
    isolate.kill(priority: Isolate.immediate);

    stopwatch.stop();

    setState(() {
      _isComputing = false;
      _result = 'SPAWN - Fibonacci($n) = $result (Elapsed time: ${stopwatch.elapsed.inSeconds}s)';
      _imageUrls = List<String>.from(_imageUrls.reversed);
    });
    print(_result);
  }

  static void calculateFibonacciSpawn(List<dynamic> values) {
    SendPort sendPort = values[0];
    int n = values[1];

    int fibonacci(int n) {
      if (n == 0) return 0;
      if (n == 1) return 1;
      return fibonacci(n - 1) + fibonacci(n - 2);
    }

    final int result = fibonacci(n);
    sendPort.send(result);
  }

  ///WITHOUT ISOLATES
  Future<void> executeComplexMathWithoutIsolate() async {
    setState(() {
      _isComputing = true;
      _result = '';
    });

    const int n = 43; // Fibonacci number to calculate

    final stopwatch = Stopwatch()..start();
    final result = calculateFibonacciWithoutIsolate(n);
    stopwatch.stop();

    setState(() {
      _isComputing = false;
      _result = 'WITHOUT - Fibonacci($n) = $result (Elapsed time: ${stopwatch.elapsed.inSeconds}s)';
      _imageUrls = List<String>.from(_imageUrls.reversed);
    });

    print(_result);
  }

  static int calculateFibonacciWithoutIsolate(int n) {
    if (n == 0) return 0;
    if (n == 1) return 1;

    return calculateFibonacciWithoutIsolate(n - 1) + calculateFibonacciWithoutIsolate(n - 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Isolate Example'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.count(
              crossAxisCount: 3,
              children: List.generate(_imageUrls.length, (index) {
                final imageUrl = _imageUrls[index];
                return GridTile(
                  child: GestureDetector(
                    child: Image.network(imageUrl),
                    onTap: () {
                      var snackBar = SnackBar(
                        content: Text(imageUrl),
                        duration: const Duration(seconds: 1),
                      );

                      ScaffoldMessenger.of(context).showSnackBar(snackBar);
                    },
                  ),
                );
              }),
            ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton(
              onPressed: loadImages,
              child: const Text('Refresh'),
            ),
            TextButton(
              onPressed: executeComplexMath,
              child: const Text('Compute Isolate'),
            ),
            TextButton(
              onPressed: executeComplexMathSpawn,
              child: const Text('Spawn Isolate'),
            ),
            TextButton(
              onPressed: executeComplexMathWithoutIsolate,
              child: const Text('NO ISOLATE'),
            ),
          ],
        ),
      ),
    );
  }
}
