import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:friction_scroll_controller/main.dart';

void main() {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final _staticCoefficientController = TextEditingController();
  final _kineticCoefficientController = TextEditingController();

  static const _presets = [
    ('Aluminum on steel', 0.61, 0.47),
  ];

  @override
  void dispose() {
    _staticCoefficientController.dispose();
    _kineticCoefficientController.dispose();

    super.dispose();
  }

  void _openFriction(double staticCoefficient, double kineticCoefficient) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FrictionPage(
          staticCoefficient: staticCoefficient,
          kineticCoefficient: kineticCoefficient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controllers = [
      _staticCoefficientController,
      _kineticCoefficientController,
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('friction_scroll_controller'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _CoefficientField(
                        label: 'Static friction coefficient',
                        controller: _staticCoefficientController,
                      ),
                      const SizedBox(height: 16),
                      _CoefficientField(
                        label: 'Kinetic friction coefficient',
                        controller: _kineticCoefficientController,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                ListenableBuilder(
                  listenable: Listenable.merge(controllers),
                  builder: (context, child) {
                    final coefficientsValid = controllers.every(
                      (c) => _isValidCoefficient(c, allowEmpty: false),
                    );

                    void openFriction() {
                      _openFriction(
                        double.parse(_staticCoefficientController.text),
                        double.parse(_kineticCoefficientController.text),
                      );
                    }

                    return OutlinedButton(
                      onPressed: coefficientsValid ? openFriction : null,
                      child: const Icon(Icons.send),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Spacer(),
              Text('or use preset coefficients'),
              Spacer(),
            ],
          ),
          const SizedBox(height: 24),
          for (final (i, preset) in _presets.indexed) ...[
            if (i > 0) const SizedBox(height: 16),
            _PresetButton(
              materials: preset.$1,
              static: preset.$2,
              kinetic: preset.$3,
            ),
          ],
        ],
      ),
    );
  }
}

class _CoefficientField extends StatelessWidget {
  const _CoefficientField({
    required this.label,
    required this.controller,
  });

  final String label;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          labelText: label,
          errorStyle: const TextStyle(height: 0),
          errorText:
              _isValidCoefficient(controller, allowEmpty: true) ? null : '',
        ),
      ),
    );
  }
}

bool _isValidCoefficient(
  TextEditingController controller, {
  required bool allowEmpty,
}) {
  if (allowEmpty && controller.text.isEmpty) {
    return true;
  }
  return double.tryParse(controller.text) != null;
}

class _PresetButton extends StatelessWidget {
  const _PresetButton({
    required this.materials,
    required this.static,
    required this.kinetic,
  });

  final String materials;
  final double static;
  final double kinetic;

  void _onTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FrictionPage(
          staticCoefficient: static,
          kineticCoefficient: kinetic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () => _onTap(context),
      child: Row(
        children: [
          Expanded(child: Text(materials)),
          const SizedBox(width: 4),
          Text(
            'µₛ $static µₖ $kinetic',
            style: const TextStyle(
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(Icons.send),
        ],
      ),
    );
  }
}

class FrictionPage extends StatefulWidget {
  const FrictionPage({
    super.key,
    required this.staticCoefficient,
    required this.kineticCoefficient,
  });

  final double staticCoefficient;
  final double kineticCoefficient;

  @override
  State<FrictionPage> createState() => _FrictionPageState();
}

class _FrictionPageState extends State<FrictionPage> {
  late final _controller = FrictionScrollController(
    staticFrictionCoefficient: widget.staticCoefficient,
    kineticFrictionCoefficient: widget.kineticCoefficient,
  );

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'µₛ ${widget.staticCoefficient} µₖ ${widget.kineticCoefficient}',
        ),
      ),
      body: ListView.builder(
        controller: _controller,
        itemCount: 1000,
        itemBuilder: (context, i) => Container(
          height: 100,
          color: i.isEven ? Colors.grey[300] : Colors.grey[400],
          child: Center(
            child: Text(
              '$i',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
          ),
        ),
      ),
    );
  }
}
