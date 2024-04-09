import 'dart:ffi';
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
import 'package:collection/collection.dart';

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
      appBar: AppBar(title: Text(widget.title), surfaceTintColor: Colors.transparent),
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

  Map<String, Costume> _costumes = {
    "Costume 1": Costume({
      0: [
        Led(0, 100, 100),
        Led(1, 200, 100)
      ],
      1: [
        Led(2, 100, 200),
        Led(3, 200, 200)
      ]
    }),
    "Costume 2": Costume({
      0: [
        Led(4, 100, 150),
        Led(5, 200, 150)
      ],
      1: [
        Led(6, 100, 250),
        Led(7, 200, 250)
      ]
    }),
  };

  late Costume _costume;
  late List<Led> _leds = [];

  Map<int, String> _ledToSequences = {}; 

  List<Color> _colors = List<Color>.filled(8, Colors.black);

  int? _selectedId;
  Effect? _selectedEffect;
  bool _inEffectSettings = false;

  double _multiplier = 1.0;
  double _previousMultiplier = 1.0;
  double _elapsedFraction = 0.0;

  late double _dragOfset;
  late double _draggedEffectWidth;

  Map<String, List<Effect>> _sequences = {"sequence 1": [], "sequence 2" : []};
  late String _selectedSequence;

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
    _costume = _costumes["Costume 1"]!;
    for (var costume in _costumes.keys){
      for (var strip in _costumes[costume]!.strips.keys){
        for(var led in _costumes[costume]!.strips[strip]!){
          _leds.add(led);
        }
      }
    }
    super.initState();
    _initWaveform();
    player = AudioPlayer();
    player.positionUpdater = TimerPositionUpdater(
      interval: const Duration(milliseconds: 33),
      getPosition: player.getCurrentPosition,
    );
    _playerState = player.state;
    _selectedSequence = _sequences.keys.last;
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
    Map<String, Map<String, List<String>>> payload = _costumes.map((name, costume) => MapEntry(name, costume.strips.map((key, value) => MapEntry(key.toString(), []))));
    setState(() {
      _position = p;
      _elapsedFraction = _position!.inMicroseconds / _duration!.inMicroseconds;
      for (int i = 0; i < _leds.length; i++) {
        if (_sequences[_ledToSequences[i]] != null){
          Effect? effect = _sequences[_ledToSequences[i]]!.firstWhere((effect) => effect.start <= p && effect.end >= p, orElse: () => SolidColorEffect(p, p, Colors.black));
          _leds[i].color = effect.getColor(p);
        }
      }
    });

    for (var costume in _costumes.keys){
      for (var strip in _costumes[costume]!.strips.keys){
        for(var led in _costumes[costume]!.strips[strip]!){
          Color color = _leds[led.id].color;
          payload[costume]![strip.toString()]!.add("${createPackedColor(color.red, color.green, color.blue)}");
        }
      }
    }
    sendPackage(jsonEncode(payload));
  }

  void _onLedTapped(int index) {
    setState(() {
      _selectedEffect = null;
      _ledToSequences[index] ??= _selectedSequence;
      _selectedSequence = _ledToSequences[index] ?? _selectedSequence;
      _selectedId = index;
      if (_ledToSequences[index] == null) {
        _ledToSequences[index] = _selectedSequence;
      }
    });
    _onPositionChanged(_position!);
  }

  void _onWidthChanged(ScaleUpdateDetails details, double maxWidth) {
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
    Effect? previousEffect = _sequences[_selectedSequence]!.lastWhereOrNull((previousEffect) => previousEffect.start <= effect.start);
    Effect? nextEffect = _sequences[_selectedSequence]!.firstWhereOrNull((nextEffect) => nextEffect.start >= effect.start);

    if (previousEffect != null) {
      effect.previousEffect = previousEffect;
      previousEffect.nextEffect = effect;
      if (previousEffect.end >= effect.start) {
        setState(() {previousEffect.end = effect.start;});
      }
    }

    if (nextEffect != null) {
      effect.nextEffect = nextEffect;
      nextEffect.previousEffect = effect;
      if (nextEffect.start <= effect.end) {
        effect.end = nextEffect.start;
      }
    }

    setState(() {
      _sequences[_selectedSequence]!.insert(_sequences[_selectedSequence]!.lastIndexWhere((previousEffect) => previousEffect.end <= effect.start) + 1, effect);
    });
  }

  void _onEffectDragged(Effect effect, DragUpdateDetails details, double maxWidth) {
    Duration startDelta = Duration(microseconds: (_duration!.inMicroseconds * ((effect.start.inMicroseconds / _duration!.inMicroseconds) + (details.delta.dx/maxWidth))).toInt());
    Duration endDelta = Duration(microseconds: (_duration!.inMicroseconds * ((effect.end.inMicroseconds / _duration!.inMicroseconds) + (details.delta.dx/maxWidth))).toInt());
    if (effect == _selectedEffect && _dragOfset <= _draggedEffectWidth * 0.4){
      if (effect.previousEffect == null || effect.previousEffect!.end < startDelta) {
        setState(() {
        effect.start = startDelta;
        });
      }
    }
    else if (effect == _selectedEffect && _dragOfset >= _draggedEffectWidth * 0.6) {
      if (effect.nextEffect == null || effect.nextEffect!.start > endDelta) {
        setState(() {
        effect.end = endDelta;
        });
      }
    }

    else if (effect != _selectedEffect){
      if ((effect.nextEffect == null || effect.nextEffect!.start > endDelta) && (effect.previousEffect == null || effect.previousEffect!.end < startDelta)) {
        setState(() {
          effect.start = startDelta;
          effect.end = endDelta;
        });
      }
    }
    _onPositionChanged(_position!);
  }

  void _onColorChanged(Color color) {
    setState(() {
      for (int i = 0; i < _leds.length; i++) {
        if (_ledToSequences[i] == _selectedSequence){
          _leds[i].color = color;
        }
      }
    });
    // sendPackage("$_selectedId,${color.red},${color.green},${color.blue}");
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            InteractiveViewer(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: Stack(
                  children: [
                    for (var strip in _costume.strips.values)
                      for (var i = 0; i < strip.length; i++)
                      Positioned(
                        left: strip[i].x,
                        top: strip[i].y,
                        child: GestureDetector(
                          onTap: () => _onLedTapped(_leds.indexOf(strip[i])),
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              boxShadow: _leds.indexOf(strip[i]) == _selectedId ? [BoxShadow(
                                blurRadius: 5.0,
                                blurStyle: BlurStyle.outer,
                                color: Colors.grey
                              )] : [],
                              color: strip[i].color,
                              border: Border.all(width: 1.0, color:  Colors.grey),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                                    child: Text(
                                    i.toString(),
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
            Positioned(
              top: 50,
              right: 10,
              child: Container(
                height: 300,
                width: 50,
                child: ListView(
                  children: [
                    for (var costume in _costumes.keys)
                      IconButton(
                        onPressed: () => setState(() {
                          _costume = _costumes[costume]!;
                        }),
                        icon: Icon(Icons.numbers)
                      )
                  ]
                ),
              ),
            )
          ],
        ),
        Expanded(
          child: Center(
            child: StreamBuilder<WaveformProgress>(
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

                return !_inEffectSettings ? Column(
                  children: [
                    Container(
                      height: 50.0,
                      child: Row(
                        children: _selectedEffect == null ? [
                          Expanded(child: Center(child: Text("No effect selected")))
                        ]
                        : [
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => setState(() {
                              _selectedEffect = null;
                            }),
                          ),
                          Spacer(),
                          Text(_selectedEffect.toString()),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.palette),
                            onPressed: () => {
                              setState(() {_inEffectSettings = true;}),
                              _onColorChanged(_selectedEffect!.getColor(_selectedEffect!.start))
                              },
                          )
                        ],
                      ),
                    ),
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
                              ? Icon(Icons.pause)
                              : Icon(Icons.play_arrow),
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
                                              child: GestureDetector(
                                                onLongPress: () => {

                                                  setState(() {_selectedEffect = effect;})
                                                },
                                                onHorizontalDragUpdate: (details) => _onEffectDragged(effect, details, constraints.maxWidth),
                                                onHorizontalDragStart: (details) => setState(() {
                                                  _dragOfset = details.localPosition.dx;
                                                  _draggedEffectWidth = constraints.maxWidth * (effect.end.inMicroseconds / _duration!.inMicroseconds) - constraints.maxWidth * (effect.start.inMicroseconds / _duration!.inMicroseconds);
                                                }),
                                                child: Container(
                                                  width: constraints.maxWidth * (effect.end.inMicroseconds / _duration!.inMicroseconds) - constraints.maxWidth * (effect.start.inMicroseconds / _duration!.inMicroseconds),
                                                  height: 100,
                                                  decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.only(topLeft: Radius.elliptical(10 / _multiplier, 10), topRight: Radius.elliptical(10 / _multiplier, 10)),
                                                    border: effect == _selectedEffect ? Border(
                                                      left: BorderSide(width: 1, color: Colors.grey),
                                                      right: BorderSide(width: 1, color: Colors.grey)
                                                    ) 
                                                    : Border.all(style: BorderStyle.none),
                                                    color: effect.getColor(effect.start)
                                                  ),
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
                    ),
                    DropdownMenu(
                          menuHeight: 200.0,
                          expandedInsets: EdgeInsets.all(8.0),
                          initialSelection: _selectedSequence,
                          onSelected: (value) => {
                            setState(() {
                                _selectedEffect = null;
                                _selectedSequence = value!;
                                _ledToSequences[_selectedId!] = _selectedSequence;
                            }),
                            _onPositionChanged(_position!)
                          },
                          dropdownMenuEntries: [
                            for (var sequence in _sequences.keys)
                              DropdownMenuEntry(
                                  value: sequence,
                                  label: sequence,
                                  labelWidget: Container(
                                    width: MediaQuery.of(context).size.width -
                                        40.0,
                                    child: Row(
                                      children: [
                                        Text(sequence),
                                        IconButton(
                                            onPressed: () => {},
                                            icon: Icon(Icons.edit)),
                                        Spacer(),
                                        IconButton(
                                            onPressed: () => setState(() {
                                                _sequences["$sequence copy"] = _sequences[sequence]!.map((effect) => effect.clone()).toList();
                                                _selectedSequence = "$sequence copy";
                                              }),
                                            icon: Icon(Icons.copy)),
                                        IconButton(
                                            onPressed: () => setState(() {
                                              if (_selectedSequence == sequence)
                                                _selectedSequence = _sequences.keys.lastWhere((name) => name != sequence);
                                              _sequences.remove(sequence);
                                            }),
                                            icon: Icon(Icons.delete_forever)),
                                      ],
                                    ),
                                  )),
                          ])
                  ],
                ): Column(
                  children: [
                    IconButton(
                      onPressed: () => {
                        setState(() {_inEffectSettings = false;}),
                        _onPositionChanged(_position!)
                      },
                      icon: Icon(Icons.check)
                    ),
                    _selectedEffect!.settings(_onColorChanged),
                  ],
                );
              },
            )
          )
        ),
        
      ],
    );
  }
}

void sendPackage(data) async {

  RawDatagramSocket udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4209);
  udp.send(utf8.encode(data), InternetAddress('192.168.43.11'), 4210);
  print("$data sent.");
}

int createPackedColor(int red, int green, int blue) {
  return (65536 * red) + (256 * green) + blue;
}

class Effect {

  late Duration start;
  late Duration end;

  Effect? previousEffect;
  Effect? nextEffect;

  Effect(this.start, this.end);

  Color getColor(Duration p) {
    return Colors.black;
  }

  Widget settings(onColorChanged) {
    return Text("No settings defined");
  }

  Effect clone() {
      return Effect(start, end);
  }
  
}

class SolidColorEffect extends Effect {

  Color color = Colors.black;

  SolidColorEffect(Duration start, Duration end, this.color) : super(start, end);

  @override
  Color getColor(Duration p) {
    return color;
  }

  @override
  Widget settings(onColorChanged) {
    return ColorPicker(
      enableShadesSelection: false,
      onColorChanged: (color) => {
        this.color = color,
        onColorChanged(color),
        },
      color: this.color,
      pickersEnabled: const {
        ColorPickerType.primary: false,
        ColorPickerType.accent: false,
        ColorPickerType.wheel: true
      },
    );
  }

  @override
  Effect clone() {
    return SolidColorEffect(start, end, color);
  }
}


class Costume {
  Map<int, List<Led>> strips = {};
  Costume(this.strips);
}

class Led {
  late int id;
  late double x;
  late double y;
  Color color = Colors.black;
  Led(this.id, this.x, this.y);
}