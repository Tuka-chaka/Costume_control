import 'dart:math';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';

import 'package:flex_color_picker/flex_color_picker.dart';
import 'dart:io';
import 'dart:convert';


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const appTitle = 'Костюмчик';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      color: Color(0xfff0f0f0),
      theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xffd0d0d0)
      ),
      title: appTitle,
      home: MyHomePage(title: appTitle),
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
  int _selectedIndex = 0;
  static const TextStyle optionStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold);
  static const List<Widget> _widgetOptions = <Widget>[
    PatternViewPage(),
    Text(
      'Index 1: Business',
      style: optionStyle,
    ),
    Text(
      'Index 2: School',
      style: optionStyle,
    ),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _widgetOptions[_selectedIndex],
      ),
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text('Меню'),
            ),
            ListTile(
              title: const Text('Сценарии'),
              selected: _selectedIndex == 0,
              onTap: () {
                // Update the state of the app
                _onItemTapped(0);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Другое'),
              selected: _selectedIndex == 1,
              onTap: () {
                // Update the state of the app
                _onItemTapped(1);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('School'),
              selected: _selectedIndex == 2,
              onTap: () {
                // Update the state of the app
                _onItemTapped(2);
                // Then close the drawer
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PatternViewPage extends StatefulWidget {
  const PatternViewPage({super.key});

  @override
  State<PatternViewPage> createState() => _PatternViewPageState();
}

class _PatternViewPageState extends State<PatternViewPage> {

  static const _costume = {0: [100, 100], 1: [200, 100]};

  Map<int, String> _ledToSequences = {}; 

  List<Color> _colors = List<Color>.filled(_costume.length, Color.fromARGB(255, 245, 153, 153));

  int? _selectedId;

  double _multiplier = 1.0;
  double _previousMultiplier = 1.0;
  double _elapsedFraction = 0.0;

  Map<String, List<Effect>> _sequences = {"sequence 1": [], "sequence 2" : []};
  String _selectedSequence = "sequence 1";

  PlayerState? _playerState;
  Duration? _duration = Duration.zero;
  Duration? _position = Duration.zero;
  bool _isPlaying = false;

  late AudioPlayer player = new AudioPlayer();

  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerCompleteSubscription;
  StreamSubscription? _playerStateChangeSubscription;
  
  final progressStream = BehaviorSubject<WaveformProgress>();

  @override
  void initState() {
    super.initState();
    _initWaveform();
    player = AudioPlayer();
    _playerState = player.state;
    _initPlayer();
    player.getDuration().then(
          (value) => setState(() {
            _duration = value;
          }),
        );
    player.getCurrentPosition().then(
          (value) => setState(() {
            _position = value;
          }),
        );
    _initStreams();
  }

  Future<void> _initWaveform() async {

    final audioFile =
        File(p.join((await getTemporaryDirectory()).path, 'enooo2.mp3'));
    try {
      await audioFile.writeAsBytes(
          (await rootBundle.load('assets/enooo2.mp3')).buffer.asUint8List());
      final waveFile =
          File(p.join((await getTemporaryDirectory()).path, 'waveform.wave'));
      JustWaveform.extract(audioInFile: audioFile, waveOutFile: waveFile)
          .listen(progressStream.add, onError: progressStream.addError);
    } catch (e) {
      progressStream.addError(e);
    }

  }

  void _initPlayer() async {
    await player.setSource(AssetSource("enooo2.mp3"));
  }

  void _initStreams() {
    _durationSubscription = player.onDurationChanged.listen((duration) {
      setState(() => _duration = duration);
    });

    _positionSubscription = player.onPositionChanged.listen(
      (p) => _onPositionChanged(p),
    );

    _playerCompleteSubscription = player.onPlayerComplete.listen((event) {
      setState(() {
        _playerState = PlayerState.stopped;
        _position = Duration.zero;
      });
    });

    _playerStateChangeSubscription =
        player.onPlayerStateChanged.listen((state) {
      setState(() {
        _playerState = state;
      });
    });
  }

  void _onPlayingChanged() async{
    _isPlaying? await player.pause() : await player.resume();
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  void _onPositionChanged(Duration p) {
    print(_ledToSequences[0]);
    setState(() {
      _position = p;
      _elapsedFraction = _position!.inMicroseconds / _duration!.inMicroseconds;
      for (int i = 0; i < _colors.length; i++) {
        Effect? effect = _sequences[_selectedSequence]!.firstWhere((effect) => effect.start <= p && effect.end >= p, orElse: () => SolidColorEffect(p, p, Colors.black));
        _colors[i] = effect.getColor(p);
      }
    });
  }

  void _onLedTapped(int index) {
    setState(() {
      _selectedId = index;
      if (_ledToSequences[index] == null) {
        _ledToSequences[index] = _selectedSequence;
      }
    });
  }

  void _onWidthChanged(ScaleUpdateDetails details, maxWidth) {
    if (details.pointerCount == 2)
    setState(() {
      _multiplier = details.horizontalScale * _previousMultiplier;
    });
    
    else if (details.pointerCount == 1){
    _isPlaying = false;
    player.pause();
    player.seek(Duration(microseconds: (_duration!.inMicroseconds * (_elapsedFraction - (details.focalPointDelta.dx/maxWidth/_multiplier) * 2 )).toInt()));
    }
  }

  void _onScaleEnded() {
    if (_multiplier >= 1.0)
    setState(() {
      _previousMultiplier = _multiplier;
    });

    else setState(() {
      _multiplier = 1.0;
    });
  }

  void _onEffectAdded(Effect effect) {
    setState(() {
      _sequences[_selectedSequence] = [..._sequences[_selectedSequence]!, effect];
    });
  }

  void onColorChanged(Color color) {
    setState(() {
      _colors[_selectedId!] = color;
    });

    sendPackage("$_selectedId,${color.red},${color.green},${color.blue}");
    
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InteractiveViewer(
          child: SizedBox(
            height: 450,
            child: Stack(
              children: [
                for (var id in _costume.keys) 
                  Positioned(
                    left: _costume[id]![0].toDouble(),
                    top: _costume[id]![1].toDouble(),
                    child: GestureDetector(
                      onTap: () => _onLedTapped(id),
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _colors[id],
                          border: Border.all(width: 1.0, color:  Colors.grey),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                                child: Text(
                                id.toString(),
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 10
                                ),
                                )
                                )
                      ),
                    )
                  )
              ] 
            ) 
          ),
        ),
        Expanded(
          child: Center(
            child: _selectedId == null ? StreamBuilder<WaveformProgress>(
              stream: progressStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${snapshot.error}',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                  );
                }
                final progress = snapshot.data?.progress ?? 0.0;
                final waveform = snapshot.data?.waveform;
                if (waveform == null) {
                  return Center(
                    child: LinearProgressIndicator(
                      value: progress,
                      )
                  );
                }

                return  Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 100,
                          width: 50,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.0, color:  Colors.grey),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(10),
                            )
                          ),
                          child: IconButton(
                            icon: _isPlaying
                              ? Icon(
                                  Icons.pause_circle_outline,
                                  size: 40.0,
                                )
                              : Icon(Icons.play_circle_outline,
                                  size: 40.0),
                            onPressed: _onPlayingChanged
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                children: [
                                  GestureDetector(
                                  onScaleUpdate: (event) => _onWidthChanged(event, constraints.maxWidth),
                                  onScaleEnd: (event) => _onScaleEnded(),
                                  child: Container(
                                    decoration: BoxDecoration(),
                                    clipBehavior: Clip.hardEdge,
                                    child: Transform.scale(
                                      scaleX: max(_multiplier, 1.0),
                                      alignment: Alignment.centerLeft,
                                      origin: Offset(70.0, 0),
                                      child: Transform.translate(
                                        offset: Offset(-_elapsedFraction * constraints.maxWidth + 70.0, 0.0),
                                        child: PolygonWaveform(
                                          samples: waveform.data.map((e) => e.toDouble()).toList(),
                                          inactiveColor: Color(0xffcccccc),
                                          height: 100,
                                          width: constraints.maxWidth,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 69.0,
                                  child: Container(
                                    height: 100,
                                    child: VerticalDivider(
                                      color: Colors.green,
                                      width: 3.0,
                                    ),
                                  )
                                ),
                                ],
                              );
                            }
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Container(
                          height: 100,
                          width: 50,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.0, color:  Colors.grey),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                            )
                          ),
                          child: IconButton(
                            icon: Icon(Icons.add),
                            onPressed: () => _onEffectAdded(SolidColorEffect(_position!, _position! + _duration! * (1/_multiplier) * 0.05, Colors.yellow))
                          ),
                        ),
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  Container(
                                    height: 100,
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(),
                                    clipBehavior: Clip.hardEdge,
                                    child: Transform.scale(
                                      scaleX: max(_multiplier, 1.0),
                                      alignment: Alignment.centerLeft,
                                      origin: Offset(70.0, 0),
                                      child: Transform.translate(
                                        offset: Offset(-_elapsedFraction * constraints.maxWidth + 70.0, 0.0),
                                        child: Stack(
                                          alignment: Alignment.centerLeft,
                                          children: [
                                            for (Effect effect in _sequences[_selectedSequence]!)
                                            Positioned(
                                              left: constraints.maxWidth * (effect.start.inMicroseconds / _duration!.inMicroseconds),
                                              child: Container(
                                                width: constraints.maxWidth * (effect.end.inMicroseconds / _duration!.inMicroseconds) - constraints.maxWidth * (effect.start.inMicroseconds / _duration!.inMicroseconds),
                                                height: 100,
                                                decoration: BoxDecoration(
                                                  color: effect.getColor(effect.start)
                                                ),
                                              )
                                            )
                                          ],
                                        )
                                      ),
                                    ),
                                  ),
                                Positioned(
                                  left: 69.0,
                                  child: Container(
                                        height: 100,
                                        child: VerticalDivider(
                                          color: Colors.green,
                                          width: 3.0,
                                        ),
                                      )),

                                ],
                              );
                            }
                          ),
                        ),
                      ]
                    )
                  ],
                );
              },
            )
                : ColorPicker(
                    enableShadesSelection: false,
                    onColorChanged: onColorChanged,
                    color: _colors[_selectedId!],
                    pickersEnabled: const {
                      ColorPickerType.primary: false,
                      ColorPickerType.accent: false,
                      ColorPickerType.wheel: true
                      },
                  ),
          )
        ),
        DropdownMenu(
          expandedInsets: EdgeInsets.all(8.0),
          dropdownMenuEntries: 
          [
            for (var sequence in _sequences.keys)
            DropdownMenuEntry(value: sequence, label: sequence)
          ]
        )
      ],
    );
  }
}



void sendPackage(data) async {

  RawDatagramSocket udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4209);
  udp.send(utf8.encode(data), InternetAddress('192.168.43.11'), 4210);
  print("$data sent.");
  }

class Effect {

  late Duration start;
  late Duration end;

  Effect(this.start, this.end);

  Color getColor(Duration p) {
    return Colors.black;
  }
  
  
}

class SolidColorEffect extends Effect {

  Color color = Colors.black;

  SolidColorEffect(Duration start, Duration end, this.color) : super(start, end);

  @override
  Color getColor(Duration p) {
    return color;
  }

}