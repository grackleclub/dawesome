import 'package:flutter/material.dart';
// import 'dart:typed_data';
// import 'package:flutter/services.dart';
import 'package:english_words/english_words.dart';
import 'package:provider/provider.dart';
// import 'package:sound_generator/sound_generator.dart';
// import 'package:sound_generator/waveTypes.dart';
// import 'dart:ui';

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
        page = Placeholder();
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

// class SynthPage extends StatefulWidget {
//   const SynthPage({Key? key}) : super(key: key);

//   @override
//   State<SynthPage> createState() => _SynthPageState();
// }

// class MyPainter extends CustomPainter {
//   //         <-- CustomPainter class
//   final List<int> oneCycleData;

//   MyPainter(this.oneCycleData);

//   @override
//   void paint(Canvas canvas, Size size) {
//     var i = 0;
//     List<Offset> maxPoints = [];

//     final t = size.width / (oneCycleData.length - 1);
//     for (var i0 = 0, len = oneCycleData.length; i0 < len; i0++) {
//       maxPoints.add(
//         Offset(
//           t * i,
//           size.height / 2 -
//               oneCycleData[i0].toDouble() / 32767.0 * size.height / 2,
//         ),
//       );
//       i++;
//     }

//     final paint =
//         Paint()
//           ..color = Colors.black
//           ..strokeWidth = 1
//           ..strokeCap = StrokeCap.round;
//     canvas.drawPoints(PointMode.polygon, maxPoints, paint);
//   }

//   @override
//   bool shouldRepaint(MyPainter oldDelegate) {
//     if (oneCycleData != oldDelegate.oneCycleData) {
//       return true;
//     }
//     return false;
//   }
// }

// class _SynthPageState extends State<SynthPage> {
//   bool isPlaying = false;
//   double frequency = 20;
//   double balance = 0;
//   double volume = 1;
//   double dB = 0;
//   waveTypes waveType = waveTypes.SINUSOIDAL;
//   int sampleRate = 192000;
//   List<int>? oneCycleData;

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(title: const Text('Sound Generator Example')),
//         body: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               const Text("A Cycle's Snapshot With Real Data"),
//               const SizedBox(height: 2),
//               Container(
//                 height: 100,
//                 width: double.infinity,
//                 color: Colors.white54,
//                 padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 0),
//                 child:
//                     oneCycleData != null
//                         ? CustomPaint(painter: MyPainter(oneCycleData!))
//                         : Container(),
//               ),
//               const SizedBox(height: 2),
//               Text(
//                 "A Cycle Data Length is ${(sampleRate / frequency).round()} on sample rate $sampleRate",
//               ),
//               const SizedBox(height: 5),
//               const Divider(color: Colors.red),
//               const SizedBox(height: 5),
//               CircleAvatar(
//                 radius: 30,
//                 backgroundColor: Colors.lightBlueAccent,
//                 child: IconButton(
//                   icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
//                   onPressed: () {
//                     isPlaying ? SoundGenerator.stop() : SoundGenerator.play();
//                   },
//                 ),
//               ),
//               const SizedBox(height: 5),
//               const Divider(color: Colors.red),
//               const SizedBox(height: 5),
//               const Text("Wave Form"),
//               Center(
//                 child: DropdownButton<waveTypes>(
//                   value: waveType,
//                   onChanged: (waveTypes? newValue) {
//                     setState(() {
//                       waveType = newValue!;
//                       SoundGenerator.setWaveType(waveType);
//                     });
//                   },
//                   items:
//                       waveTypes.values.map((waveTypes classType) {
//                         return DropdownMenuItem<waveTypes>(
//                           value: classType,
//                           child: Text(classType.toString().split('.').last),
//                         );
//                       }).toList(),
//                 ),
//               ),
//               const SizedBox(height: 5),
//               const Divider(color: Colors.red),
//               const SizedBox(height: 5),
//               const Text("Frequency"),
//               SizedBox(
//                 width: double.infinity,
//                 height: 40,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: <Widget>[
//                     Expanded(
//                       flex: 2,
//                       child: Center(
//                         child: Text("${frequency.toStringAsFixed(2)} Hz"),
//                       ),
//                     ),
//                     Expanded(
//                       flex: 8, // 60%
//                       child: Slider(
//                         min: 20,
//                         max: 10000,
//                         value: frequency,
//                         onChanged: (value) {
//                           setState(() {
//                             frequency = value.toDouble();
//                             SoundGenerator.setFrequency(frequency);
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 5),
//               const Text("Balance"),
//               SizedBox(
//                 width: double.infinity,
//                 height: 40,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: <Widget>[
//                     Expanded(
//                       flex: 2,
//                       child: Center(child: Text(balance.toStringAsFixed(2))),
//                     ),
//                     Expanded(
//                       flex: 8, // 60%
//                       child: Slider(
//                         min: -1,
//                         max: 1,
//                         value: balance,
//                         onChanged: (value) {
//                           setState(() {
//                             balance = value.toDouble();
//                             SoundGenerator.setBalance(balance);
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 5),
//               const Text("Volume"),
//               SizedBox(
//                 width: double.infinity,
//                 height: 40,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: <Widget>[
//                     Expanded(
//                       flex: 2,
//                       child: Center(child: Text(volume.toStringAsFixed(6))),
//                     ),
//                     Expanded(
//                       flex: 8, // 60%
//                       child: Slider(
//                         min: 0,
//                         max: 1,
//                         value: volume,
//                         onChanged: (value) async {
//                           SoundGenerator.setVolume(volume);
//                           double newDB = await SoundGenerator.getDecibel;
//                           setState(() {
//                             volume = value.toDouble();
//                             dB = newDB;
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 5),
//               const Text("Decibel"),
//               SizedBox(
//                 width: double.infinity,
//                 height: 40,
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: <Widget>[
//                     Expanded(
//                       flex: 2,
//                       child: Center(child: Text(dB.toStringAsFixed(2))),
//                     ),
//                     Expanded(
//                       flex: 8, // 60%
//                       child: Slider(
//                         min: -120,
//                         max: 0,
//                         value: dB,
//                         onChanged: (value) async {
//                           SoundGenerator.setDecibel(value.toDouble());
//                           double newVolume = await SoundGenerator.getVolume;
//                           setState(() {
//                             dB = value.toDouble();
//                             volume = newVolume;
//                           });
//                         },
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     SoundGenerator.release();
//   }

//   @override
//   void initState() {
//     super.initState();
//     isPlaying = false;

//     SoundGenerator.init(sampleRate);

//     SoundGenerator.onIsPlayingChanged.listen((value) {
//       setState(() {
//         isPlaying = value;
//       });
//     });

//     SoundGenerator.onOneCycleDataHandler.listen((value) {
//       setState(() {
//         oneCycleData = value;
//       });
//     });

//     SoundGenerator.setAutoUpdateOneCycleSample(true);
//     //Force update for one time
//     SoundGenerator.refreshOneCycleData();
//   }
// }
