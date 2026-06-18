import 'package:flutter/material.dart';
import '/services/trader_service.dart';

class TestApiScreen extends StatefulWidget {
  const TestApiScreen({super.key});
  @override
  State<TestApiScreen> createState() => _TestApiScreenState();
}

class _TestApiScreenState extends State<TestApiScreen> {
  String _result = 'Loading...';

  @override
  void initState() {
    super.initState();
    _test();
  }

  Future<void> _test() async {
    final res = await TraderService().getHome();
    setState(() => _result = res.toString());
    print('🏠 HOME: $res');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Test')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(_result),
      ),
    );
  }
}