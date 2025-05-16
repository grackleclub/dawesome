import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:sonic_frequencies/sonic_frequencies.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Dawesome',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  var history = <WordPair>[];

  GlobalKey? historyListKey;

  void getNext() {
    history.insert(0, current);
    var animatedList = historyListKey?.currentState as AnimatedListState?;
    animatedList?.insertItem(0);
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }

  void removeFavorite(WordPair pair) {
    favorites.remove(pair);
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;

    Widget page;
    switch (selectedIndex) {
      case 0:
        page = GeneratorPage();
        break;
      case 1:
        page = FavoritesPage();
        break;
      case 2:
        page = SynthPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    var mainArea = ColoredBox(
      color: colorScheme.surfaceContainerHighest,
      child: AnimatedSwitcher(
        duration: Duration(milliseconds: 200),
        child: page,
      ),
    );

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 450) {
            // Use a more mobile-friendly layout with BottomNavigationBar
            // on narrow screens.
            return Column(
              children: [
                Expanded(child: mainArea),
                SafeArea(
                  child: BottomNavigationBar(
                    items: [
                      BottomNavigationBarItem(
                        icon: Icon(Icons.home),
                        label: 'Home',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.favorite),
                        label: 'Favorites',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.volume_up),
                        label: 'Synth',
                      ),
                    ],
                    currentIndex: selectedIndex,
                    onTap: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
              ],
            );
          } else {
            return Row(
              children: [
                SafeArea(
                  child: NavigationRail(
                    extended: constraints.maxWidth >= 600,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.home),
                        label: Text('Home'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.favorite),
                        label: Text('Favorites'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.volume_up),
                        label: Text('Synth'),
                      ),
                    ],
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) {
                      setState(() {
                        selectedIndex = value;
                      });
                    },
                  ),
                ),
                Expanded(child: mainArea),
              ],
            );
          }
        },
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(flex: 3, child: HistoryListView()),
          SizedBox(height: 10),
          BigCard(pair: pair),
          SizedBox(height: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  appState.toggleFavorite();
                },
                icon: Icon(icon),
                label: Text('Like'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  appState.getNext();
                },
                child: Text('Next'),
              ),
            ],
          ),
          Spacer(flex: 2),
        ],
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var appState = context.watch<MyAppState>();

    if (appState.favorites.isEmpty) {
      return Center(child: Text('No favorites yet.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(30),
          child: Text(
            'You have '
            '${appState.favorites.length} favorites:',
          ),
        ),
        Expanded(
          // Make better use of wide windows with a grid.
          child: GridView(
            gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 400,
              childAspectRatio: 400 / 80,
            ),
            children: [
              for (var pair in appState.favorites)
                ListTile(
                  leading: IconButton(
                    icon: Icon(Icons.delete_outline, semanticLabel: 'Delete'),
                    color: theme.colorScheme.primary,
                    onPressed: () {
                      appState.removeFavorite(pair);
                    },
                  ),
                  title: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({super.key, required this.pair});

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onSecondary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSize(
          duration: Duration(milliseconds: 200),
          child: MergeSemantics(
            child: Wrap(
              children: [
                Text(
                  pair.first,
                  style: style.copyWith(fontWeight: FontWeight.w200),
                ),
                Text(
                  pair.second,
                  style: style.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HistoryListView extends StatefulWidget {
  const HistoryListView({super.key});

  @override
  State<HistoryListView> createState() => _HistoryListViewState();
} //class

class _HistoryListViewState extends State<HistoryListView> {
  final _key = GlobalKey();

  static const Gradient _maskingGradient = LinearGradient(
    colors: [Colors.transparent, Colors.black],
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  ); // static const

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyListKey = _key;

    return ShaderMask(
      shaderCallback: (bounds) => _maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _key,
        reverse: true,
        padding: EdgeInsets.only(top: 100),
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          final pair = appState.history[index];
          return SizeTransition(
            sizeFactor: animation,
            child: Center(
              child: TextButton.icon(
                //TextButton
                onPressed: () {
                  appState.toggleFavorite();
                }, //onPressed
                icon:
                    appState.favorites.contains(pair)
                        ? Icon(Icons.favorite, size: 12)
                        : SizedBox(),
                label: Text(
                  pair.asLowerCase,
                  semanticsLabel: pair.asPascalCase,
                ),
              ), //label
            ), //Center
          ); //SizeTransition
        }, //itemBuilder
      ), //AnimatedList
    ); //ShaderMask
  } //Widget
} //class

class SynthPage extends StatefulWidget {
  const SynthPage({super.key});

  @override
  State<SynthPage> createState() => _SynthPageState();
}

class _SynthPageState extends State<SynthPage> {
  String _platformVersion = 'Unknown';
  final _sonicFrequenciesPlugin = SonicFrequencies();
  bool _isPlaying = false;
  double _frequency = 440.0;
  double _volume = 1.0;
  int _duration = 3000;
  double _startFrequency = 200.0;
  double _endFrequency = 2000.0;

  // Predefined frequencies for repelling different insects
  final Map<String, double> _insectFrequencies = {
    'Mosquitoes': 18000.0,
    'Flies': 15000.0,
    'Cockroaches': 20000.0,
    'Ants': 22000.0,
    'Rodents': 25000.0,
  };

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  @override
  void dispose() {
    _stopTone();
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    String platformVersion;
    // Platform messages may fail, so we use a try/catch PlatformException.
    // We also handle the message potentially returning null.
    try {
      platformVersion =
          await _sonicFrequenciesPlugin.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> _generateTone() async {
    if (_isPlaying) {
      await _stopTone();
    }

    try {
      final result = await _sonicFrequenciesPlugin.generateTone(
        frequency: _frequency,
        volume: _volume,
        duration: _duration,
      );

      setState(() {
        _isPlaying = result;
      });
    } on PlatformException catch (e) {
      debugPrint('Error generating tone: ${e.message}');
    }
  }

  Future<void> _generateSweep() async {
    if (_isPlaying) {
      await _stopTone();
    }

    try {
      final result = await _sonicFrequenciesPlugin.generateSweep(
        startFrequency: _startFrequency,
        endFrequency: _endFrequency,
        duration: _duration,
        volume: _volume,
      );

      setState(() {
        _isPlaying = result;
      });
    } on PlatformException catch (e) {
      debugPrint('Error generating sweep: ${e.message}');
    }
  }

  Future<void> _stopTone() async {
    try {
      final result = await _sonicFrequenciesPlugin.stopTone();
      setState(() {
        _isPlaying = !result;
      });
    } on PlatformException catch (e) {
      debugPrint('Error stopping tone: ${e.message}');
    }
  }

  Future<void> _playInsectRepellent(String insectType) async {
    if (_isPlaying) {
      await _stopTone();
    }

    final frequency = _insectFrequencies[insectType] ?? 440.0;

    try {
      final result = await _sonicFrequenciesPlugin.generateTone(
        frequency: frequency,
        volume: _volume,
      );

      setState(() {
        _isPlaying = result;
        _frequency = frequency;
      });
    } on PlatformException catch (e) {
      debugPrint('Error generating tone: ${e.message}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sonic Frequencies'),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Running on: $_platformVersion'),
              const SizedBox(height: 20),

              // Tone Generator Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Tone Generator',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Frequency Slider
                      Row(
                        children: [
                          const Text('Frequency (Hz): '),
                          Expanded(
                            child: Slider(
                              value: _frequency,
                              min: 20.0,
                              max: 20000.0,
                              onChanged: (value) {
                                setState(() {
                                  _frequency = value;
                                });
                              },
                            ),
                          ),
                          Text(_frequency.toStringAsFixed(1)),
                        ],
                      ),

                      // Volume Slider
                      Row(
                        children: [
                          const Text('Volume: '),
                          Expanded(
                            child: Slider(
                              value: _volume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _volume = value;
                                });
                              },
                            ),
                          ),
                          Text(_volume.toStringAsFixed(2)),
                        ],
                      ),

                      // Duration Slider
                      Row(
                        children: [
                          const Text('Duration (ms): '),
                          Expanded(
                            child: Slider(
                              value: _duration.toDouble(),
                              min: 100.0,
                              max: 10000.0,
                              onChanged: (value) {
                                setState(() {
                                  _duration = value.toInt();
                                });
                              },
                            ),
                          ),
                          Text(_duration.toString()),
                        ],
                      ),

                      // Tone Control Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: _generateTone,
                            child: const Text('Play Tone'),
                          ),
                          ElevatedButton(
                            onPressed: _stopTone,
                            child: const Text('Stop'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Sweep Generator Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Frequency Sweep',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Start Frequency Slider
                      Row(
                        children: [
                          const Text('Start (Hz): '),
                          Expanded(
                            child: Slider(
                              value: _startFrequency,
                              min: 20.0,
                              max: 20000.0,
                              onChanged: (value) {
                                setState(() {
                                  _startFrequency = value;
                                });
                              },
                            ),
                          ),
                          Text(_startFrequency.toStringAsFixed(1)),
                        ],
                      ),

                      // End Frequency Slider
                      Row(
                        children: [
                          const Text('End (Hz): '),
                          Expanded(
                            child: Slider(
                              value: _endFrequency,
                              min: 20.0,
                              max: 20000.0,
                              onChanged: (value) {
                                setState(() {
                                  _endFrequency = value;
                                });
                              },
                            ),
                          ),
                          Text(_endFrequency.toStringAsFixed(1)),
                        ],
                      ),

                      // Sweep Control Button
                      Center(
                        child: ElevatedButton(
                          onPressed: _generateSweep,
                          child: const Text('Play Sweep'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Insect Repellent Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Insect Repellent Frequencies',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Insect Repellent Buttons
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children:
                            _insectFrequencies.keys.map((insect) {
                              return ElevatedButton(
                                onPressed: () => _playInsectRepellent(insect),
                                child: Text('Repel $insect'),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Status and Controls
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'Status: ${_isPlaying ? "Playing" : "Stopped"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isPlaying ? Colors.green : Colors.red,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isPlaying)
                        ElevatedButton(
                          onPressed: _stopTone,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('STOP ALL SOUNDS'),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
