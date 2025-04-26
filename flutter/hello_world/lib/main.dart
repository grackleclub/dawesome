import 'package:flutter/material.dart';
import 'dart:typed_data';

import 'package:dart_melty_soundfont/preset.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import 'package:dart_melty_soundfont/synthesizer.dart';
import 'package:dart_melty_soundfont/synthesizer_settings.dart';
import 'package:dart_melty_soundfont/audio_renderer_ex.dart';
import 'package:dart_melty_soundfont/array_int16.dart';

import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';

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
  const BigCard({Key? key, required this.pair}) : super(key: key);

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    var style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
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
  const HistoryListView({Key? key}) : super(key: key);

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
  @override
  _SynthPageState createState() => _SynthPageState();
}

class _SynthPageState extends State<SynthPage> {
  Synthesizer? _synth;
  bool _isPlaying = false;
  bool _pcmSoundLoaded = false;
  bool _soundFontLoaded = false;
  int _remainingFrames = 0;
  int _fedCount = 0;
  int _prevNote = 0;

  final String asset = 'assets/Essential-Keys-v9.sf2';
  final int sampleRate = 44100;

  @override
  void initState() {
    super.initState();
    _initializeSynthesizer();
  }

  Future<void> _initializeSynthesizer() async {
    try {
      await _loadSoundfont();
      await _loadPcmSound();
      setState(() {
        _soundFontLoaded = true;
        _pcmSoundLoaded = true;
      });
    } catch (e) {
      print("Error loading synthesizer: $e");
    }
  }

  Future<void> _loadPcmSound() async {
    try {
      FlutterPcmSound.setFeedCallback(onFeed);
      await FlutterPcmSound.setLogLevel(LogLevel.standard);
      await FlutterPcmSound.setFeedThreshold(8000);
      await FlutterPcmSound.setup(sampleRate: sampleRate, channelCount: 1);
    } catch (e) {
      print('Error setting up PCM sound: $e');
    }
  }

  Future<void> _loadSoundfont() async {
    try {
      ByteData bytes = await rootBundle.load(asset);
      _synth = Synthesizer.loadByteData(bytes, SynthesizerSettings());

      // Print available presets for debugging
      List<Preset> presets = _synth!.soundFont.presets;
      for (int i = 0; i < presets.length; i++) {
        String instrumentName =
            presets[i].regions.isNotEmpty
                ? presets[i].regions[0].instrument.name
                : "N/A";
        print(
          '[Preset $i] Name: ${presets[i].name}, Instrument: $instrumentName',
        );
      }
    } catch (e) {
      print('Error loading sound font: $e');
    }
  }

  @override
  void dispose() {
    FlutterPcmSound.release();
    _synth?.noteOffAll();
    super.dispose();
  }

  void onFeed(int remainingFrames) async {
    setState(() {
      _remainingFrames = remainingFrames;
    });

    List<int> notes = [60, 62, 64, 65, 67, 69, 71, 72];
    int step = (_fedCount ~/ 16) % notes.length;
    int curNote = notes[step];
    if (curNote != _prevNote) {
      if (_synth == null) return;
      _synth!.noteOff(channel: 0, key: _prevNote);
      _synth!.noteOn(channel: 0, key: curNote, velocity: 120);
    }
    ArrayInt16 buf16 = ArrayInt16.zeros(numShorts: 1000);
    _synth!.renderMonoInt16(buf16);
    await FlutterPcmSound.feed(PcmArrayInt16(bytes: buf16.bytes));
    _fedCount++;
    _prevNote = curNote;
  }

  Future<void> _play() async {
    if (_isPlaying) return;

    if (_synth == null) {
      print("Synthesizer not initialized");
      return;
    }

    try {
      await FlutterPcmSound.setup(sampleRate: sampleRate, channelCount: 1);
      FlutterPcmSound.start();

      setState(() {
        _isPlaying = true;
      });
    } catch (e) {
      print("Error starting playback: $e");
    }

  Future<void> _pause() async {
    await FlutterPcmSound.pause();
    setState(() {
      _isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_pcmSoundLoaded || !_soundFontLoaded) {
      return Center(child: Text("Initializing..."));
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _isPlaying ? _pause() : _play(),
          child: Text(_isPlaying ? "Pause" : "Play"),
        ),
        SizedBox(height: 20),
        Text("Remaining frames: $_remainingFrames"),
      ],
    );
  }
}
