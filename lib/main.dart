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

  static const appTitle = 'Сценарии';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      color: Color(0xfff0f0f0),
      theme: ThemeData(
      brightness: Brightness.dark,
      primaryColor: Color(0xffd0d0d0)
      ),
      title: appTitle,
      home: MyHomePage(title: appTitle, storage: DataStorage()),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.storage});
  final DataStorage storage;

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  Map<String, dynamic> _shows = {};
  Map<String, dynamic> _patterns = {};
  Map<String, dynamic> _costumes = {};
  int _selectedIndex = 0;

  static const List<String> _titleOptions = ["Сценарии", "Паттерны", "Костюмы"];

  @override
  void initState() {
    super.initState();
    widget.storage.createDirectories();
    widget.storage.readData("shows.json").then((value) {
      setState(() {
        _shows = jsonDecode(value);
      });
    });
    widget.storage.getFiles("/patterns").then((value) {
      int counter = 1;
      setState(() {
        for (var pattern in value){
          _patterns["pattern " + counter.toString()] = (jsonDecode(pattern));
          counter += 1;
        }
      });
    });
    widget.storage.getFiles("/costumes").then((value) {
      int counter = 1;
      setState(() {
        for (var costume in value){
          _costumes["costume " + counter.toString()] = jsonDecode(costume);
          counter += 1;
        }
      });
    });
    // print(widget.storage._localPath.then((value) => value));
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onButtonTapped(String showTitle) {
    Navigator.push(context,MaterialPageRoute(builder: (context) => ShowPage(title: showTitle, patterns: _shows[showTitle]["patterns"])),);
  }

  void _onCostumeAdded() {
    Navigator.push(context,MaterialPageRoute(builder: (context) => CostumePage()),);
  }

  void onShowAdded() {
    setState(() {
      _shows["show 1"] = {"costumes" : ["costume 1", "costume 2"], "patterns" : ["pattern 1", "pattern 2"]};
    });
    widget.storage.writeData(jsonEncode(_shows), "shows.json");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () => widget.storage._localPath.then((value) => print(Directory(value + "/costumes").listSync())), icon: Icon(Icons.local_pizza)),
        actions: _selectedIndex == 2 ? [] : [
          IconButton(onPressed: () => {print(_costumes["costume 1"]["0"][0]["x"])}, icon: Icon(Icons.search)),
          IconButton(onPressed: () => {}, icon: Icon(Icons.add))
        ],
        title: Text(_titleOptions[_selectedIndex]),
        surfaceTintColor: Colors.transparent
      ),
      body: _selectedIndex == 0 ?  Center(
        child: ListView(
              children: [
                for (var show in _shows.keys)
                  ListTile(
                    leading: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.man),
                        Text("x${_shows[show]["costumes"].length}")
                      ],
                    ),
                    title: Text(show),
                    subtitle: Text("${_shows[show]["patterns"].length} pattern${_shows[show]["patterns"].length > 1 ? "s" : ""}"),
                    onTap: () => _onButtonTapped(show),
                    trailing: IconButton(
                      onPressed: () => {},
                      icon: Icon(Icons.edit)),
                  )
                ] 
                // + [
                //   ListTile(
                //     leading: IconButton(
                //       onPressed: () => onShowAdded(),
                //       icon: Icon(Icons.add)),
                //     title: Text("Добавить сценарий"),
                //   )
                // ]
          ),
      ) : _selectedIndex == 1 ? Center(
        child: ListView(
          children: [
            for (var pattern in _patterns.entries)
              ListTile(
                title: Text(pattern.key),
                subtitle: Text(pattern.value["duration"]),
                onTap: () => _onButtonTapped(pattern.key),
                trailing: IconButton(
                  onPressed: () => {},
                  icon: Icon(Icons.edit)),
              )
          ]
        )
      ) : Center(
        child: Column(
          children: [
            Spacer(),
            Container(
              height: 350,
              width: MediaQuery.of(context).size.width,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (var costume in _costumes.entries)
                    Card.outlined(
                      child: Column(
                        children: [
                          SizedBox(
                          height: 310,
                          width: MediaQuery.of(context).size.width / 2,
                          child: Stack(
                            children: [
                              for (var strip in costume.value.values)
                                for (var i = 0; i < strip.length; i++)
                                Positioned(
                                  left: strip[i]["x"] / 2,
                                  top: strip[i]["y"] / 2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(width: 1.0, color:  Colors.grey),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  )
                            ] 
                          ) 
                        ),
                        Text(costume.key)
                        ],
                      ),
                    )
                ]
              ),
            ),
            Spacer(),
            Card.outlined(
              child: InkWell(
                onTap: _onCostumeAdded,
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: Icon(Icons.add, size: 30),
                  ),
                ),
              )
            )
          ],
        )
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Сценарии',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.music_note),
            label: 'Паттерны',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.man),
            label: 'Костюмы',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        onTap: _onItemTapped,
      )
    );
  }
}

class CostumePage extends StatefulWidget {
  CostumePage({super.key});

  @override
  State<CostumePage> createState() => _CostumePageState();
}

class _CostumePageState extends State<CostumePage> {

  Costume _costume = Costume({});
  String _selectedStrip = "1";
  late List<Led> _leds = [];
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = "Новый костюм";
    // DataStorage().readData("costumes/${widget.title}.json").then((value) {
    //   setState(() {
    //     Map<String, dynamic> costume = jsonDecode(value);
    //     for (var strip in costume.keys){
    //       _costume.strips[strip] = [];
    //       for(var led in costume[strip]){
    //         Led newLed = Led(led["x"], led["y"]);
    //         _leds.add(newLed);
    //         _costume.strips[strip]!.add(newLed);
    //       }
    //     }
    //   });
    //   print(_leds);
    // });
    // for (var strip in _costume.strips.keys){
    //   for(var led in _costume.strips[strip]!){
    //     _leds.add(led);
    //   }
    // }
  }

  void _onCostumeSaved() {
    Map<String, dynamic> data = {};
    for (var strip in _costume.strips.keys) {
      if (!data.keys.contains(strip)) {
        data[strip] = [];
      }
      for (var led in _costume.strips[strip]!) {
        data[strip].add({"x": led.x, "y": led.y});
      }
    }
    print(data);
    DataStorage().writeData(jsonEncode(data), "costumes/${_controller.text}.json");
  }

  void _onPointTapped(double x, double y) {
    setState(() {
      if (_costume.strips[_selectedStrip] == null) {
        _costume.strips[_selectedStrip] = [];
      }
      _costume.strips[_selectedStrip]!.add(Led(x, y));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
        ),
        actions: [IconButton(onPressed: () => {_onCostumeSaved()}, icon: Icon(Icons.check))],
        surfaceTintColor: Colors.transparent
      ),
      body: Column(
        children: [
          InteractiveViewer(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 184,
                child: Stack(
                  children:  [
                    for (var x = 0; x < 30; x++)
                      for (var y = 0; y < 35; y++)
                        Positioned(
                          left: x * 20,
                          top: y * 20,
                          child: DragTarget(
                            onAcceptWithDetails: (DragTargetDetails<int> details) {
                              setState(() {
                                _leds[details.data].x = x*20;
                                _leds[details.data].y = y*20;
                              });
                              print(_leds);
                            },
                            builder:(context, candidateData, rejectedData) => Container(
                              width: 20,
                              height: 20,
                              child: InkWell(
                                onTap: () => _onPointTapped(x * 20, y * 20),
                                child: Center(
                                  child: Container(
                                    width: 2,
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,),
                                  ),
                                ),
                              ),
                            ),
                        )
                      )
                  ] + [
                    for (var strip in _costume.strips.values)
                      for (var i = 0; i < strip.length; i++)
                         Positioned(
                          left: strip[i].x,
                          top: strip[i].y,
                          child: Draggable(
                            data: _leds.indexOf(strip[i]),
                            feedback: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    color: strip[i].color,
                                    border: Border.all(width: 1.0, color:  Colors.grey),
                                    shape: BoxShape.circle,
                                  )
                                ),
                            child: GestureDetector(
                            // onTap: () => _onLedTapped(_leds.indexOf(strip[i])),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                // boxShadow: _leds.indexOf(strip[i]) == _selectedId ? [BoxShadow(
                                //   blurRadius: 5.0,
                                //   blurStyle: BlurStyle.outer,
                                //   color: Colors.grey
                                // )] : [],
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
                        ),
                  ]
                ) 
              ),
            ), 
            Container(
              height: 100,
              // decoration: BoxDecoration(
              //   color: Colors.black
              //   ),
              child: Column(
                children: 
                  [
                    for (var i = 0; i < 2; i++)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          for (var j = 1; j < 5; j++)
                        TextButton(onPressed: () => {setState(() {
                          _selectedStrip = (i*4+j).toString();
                        })},
                        child: Text((i*4+j).toString()),
                        style: ButtonStyle(
                          foregroundColor: MaterialStateProperty.all(Colors.black),
                          backgroundColor: (i*4+j).toString() == _selectedStrip ? MaterialStateProperty.all(Colors.orange) : MaterialStateProperty.all(Colors.grey)
                          ))
                        ],
                      )
                  ],)
              )
          ]
      ),
    );
  }
}

class ShowPage extends StatefulWidget {
  ShowPage({super.key, required this.title, required this.patterns});

  final String title;
  final List<dynamic> patterns;

  @override
  State<ShowPage> createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {

  Map<String, Map<String, dynamic>> _patterns = {};

  @override
  void initState() {
    super.initState();
    print(widget.patterns);
    for (var pattern in widget.patterns){
    DataStorage().readData("patterns/$pattern.json").then((value) {
      setState(() {
        _patterns[pattern] = (jsonDecode(value));
      });
    });
    }
  }

  void _onButtonTapped(String title) {
    Navigator.push(context,MaterialPageRoute(builder: (context) => PatternViewPage(title: title)),);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        surfaceTintColor: Colors.transparent
      ),
      body: Center(
        child: ListView(
          children: [
            for (var pattern in _patterns.entries)
              ListTile(
                title: Text(pattern.key),
                subtitle: Text(pattern.value["duration"]),
                onTap: () => _onButtonTapped(pattern.key),
                trailing: IconButton(
                  onPressed: () => {},
                  icon: Icon(Icons.edit)),
              )
          ]
        )
      ),
    );
  }
}

class PatternViewPage extends StatefulWidget {
  PatternViewPage({super.key, required this.title});

  final String title;

  @override
  State<PatternViewPage> createState() => _PatternViewPageState();
}

class _PatternViewPageState extends State<PatternViewPage> {

  Map<String, Costume> _costumes = {
    "Costume 1": Costume({
      "0": [
        Led(100, 100),
        Led(200, 100)
      ],
      "1": [
        Led(100, 200),
        Led(200, 200)
      ]
    }),
    "Costume 2": Costume({
      "0": [
        Led(100, 150),
        Led(200, 150)
      ],
      "1": [
        Led(100, 250),
        Led(200, 250)
      ]
    }),
  };

  late Costume _costume;
  late List<Led> _leds = [];
  List<int> _waveformData = [];
  bool isTesting = false;

  Map<int, String> _ledToSequences = {}; 

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
    DataStorage().readData("/costumes/drummer.json").then((value) {
      Map<String, dynamic> data = jsonDecode(value);
      Costume newCostume = Costume({});
      for (var strip in data.keys) {
        newCostume.strips[strip] = [];
        for (var led in data[strip]) {
          newCostume.strips[strip]!.add(Led(led["x"], led["y"]));
        }
      }
      _costumes["Costume 1"] = newCostume;
      _costume = _costumes["Costume 1"]!;
    for (var costume in _costumes.keys){
      for (var strip in _costumes[costume]!.strips.keys){
        for(var led in _costumes[costume]!.strips[strip]!){
          _leds.add(led);
        }
      }
    }
    });
   
    DataStorage().readData("patterns/${widget.title}").then((value) {
      Map<String, dynamic> data = jsonDecode(value);
      print(data["duration"]);
      setState(() {
        for (var sequence in data["sequences"].keys){
          _sequences[sequence] = [];
          for (var effect in data["sequences"][sequence]){
            Effect newEffect = SolidColorEffect(Duration(microseconds: effect["start"]), Duration(microseconds: effect["end"]), Color(effect["color"]));
            _sequences[sequence]!.add(newEffect);
            if (_sequences[sequence]!.length > 1){
              newEffect.previousEffect = _sequences[sequence]![_sequences[sequence]!.length - 2];
              _sequences[sequence]![_sequences[sequence]!.length - 2].nextEffect = newEffect;
            }
          }
        }
        for (var led in data["leds"].keys)
          _ledToSequences[int.parse(led)] = data["leds"][led];
      });
    });
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
    Map<String, Map<String, List<String>>> payload = _costumes.map((name, costume) => MapEntry(
      name, costume.strips.map((key, value) => MapEntry(key.toString(), []))));
    setState(() {
      _position = p;
      _elapsedFraction = _position!.inMicroseconds / _duration!.inMicroseconds;
      for (int i = 0; i < _leds.length; i++) {
        if (_sequences[_ledToSequences[i]] != null){
          Effect? effect = _sequences[_ledToSequences[i]]!.firstWhere(
            (effect) => effect.start <= p && effect.end >= p, orElse: () => SolidColorEffect(p, p, Colors.black));
          _leds[i].color = effect.getColor(p);
        }
      }
    });

    for (var costume in _costumes.keys){
      for (var strip in _costumes[costume]!.strips.keys){
        for(var led in _costumes[costume]!.strips[strip]!){
          Color color = led.color;
          payload[costume]![strip.toString()]!.add("${createPackedColor(color.red, color.green, color.blue)}");
        }
      }
    }
    sendPacket(jsonEncode(payload));
    print(payload);
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
    saveData();
  }

  void _onEffectScrolled() {
    setState(() {
      
    });
    _onPositionChanged(_position!);
    saveData();
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
    saveData();
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
  }

  void _onSequenceDeleted(String sequence) {
    setState(() {
      if (_selectedSequence == sequence)
        _selectedSequence = _sequences.keys.lastWhere((name) => name != sequence);
      _sequences.remove(sequence);
      _ledToSequences.removeWhere((key, value) => value == sequence);
    });
    _onPositionChanged(_position!);
    saveData();
  }

  void _onEffectDeleted(Effect effect) {
    setState(() {
      _selectedEffect = null;
      _sequences[_selectedSequence]!.remove(effect);
      if (effect.previousEffect != null)
        effect.previousEffect!.nextEffect = effect.nextEffect;
      if (effect.nextEffect != null)
        effect.nextEffect!.previousEffect = effect.previousEffect;
    });
    _onPositionChanged(_position!);
    saveData();
  }

  void saveData() {
    Map<String, dynamic> data = {"duration": "3.55", "leds" : {}, "sequences" : {}, "waveform": progressStream.value.waveform!.data};
    for (var led in _ledToSequences.keys){
      data["leds"][led.toString()] = _ledToSequences[led];
    }

    for (var sequence in _sequences.keys) {
      data["sequences"][sequence] = [];
      for (var effect in _sequences[sequence]!)
        if (effect is SolidColorEffect)
          data["sequences"][sequence].add({"type": "SolidColorEffect", "start": effect.start.inMicroseconds, "end": effect.end.inMicroseconds, "color": effect.color.value});
      DataStorage().writeData(jsonEncode(data), "patterns/${widget.title}.json");
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: BackButton(),
        surfaceTintColor: Colors.transparent,
        actions: [
          Text("Проверка"),
          Switch(
          value: isTesting,
          onChanged: (bool value) {
            if (value) {
              for (var led in _leds)
                led.color = Colors.white;}
            else {
              for (var led in _leds)
                led.color = Colors.black;
              _onPositionChanged(_position!);
            }
            setState(() {
              isTesting = value;
            });
          },
        ),]
      ),
      body: Center(
        child: Column(
      children: [
        Stack(
          children: [
            InteractiveViewer(
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 400,
                child: Center(
                  child: Stack(
                    children: [
                      for (var strip in _costume.strips.values)
                        for (var i = 0; i < strip.length; i++)
                        Positioned(
                          left: strip[i].x*0.6,
                          top: strip[i].y*0.6,
                          child: GestureDetector(
                            onTap: () => _onLedTapped(_leds.indexOf(strip[i])),
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                boxShadow: _leds.indexOf(strip[i]) == _selectedId ? [BoxShadow(
                                  blurRadius: 3.0,
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
                                        fontSize: 5
                                      ),
                                      )
                                      )
                            ),
                          )
                        )
                    ] 
                  ),
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
                      TextButton(
                        onPressed: () => setState(() {
                          _costume = _costumes[costume]!;
                        }),
                        child: Text((_costumes.keys.toList().indexOf(costume)+1).toString()),
                        style: ButtonStyle(foregroundColor: MaterialStateProperty.all(Colors.grey))
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
                          Expanded(child: Center(child: Text("Эффект не выбран")))
                        ]
                        : [
                            IconButton(
                            icon: Icon(Icons.delete_forever),
                            onPressed: () => showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Удалить эффект?"),
                                // content: Text(_selectedEffect.toString()),
                                actions: [
                                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("нет")),
                                  TextButton(onPressed: () => {_onEffectDeleted(_selectedEffect!), Navigator.of(context).pop()}, child: Text("да"))
                                ]
                              )
                            ),
                          ),
                          Spacer(),
                            IconButton(
                            icon: Transform.scale(
                              scaleX: -1,
                              child: Icon(
                                Icons.start, 
                              ),
                            ),
                            onPressed: () => setState(() {
                              _selectedEffect = null;
                            }),
                          ),
                          Spacer(),
                          
                          IconButton(
                            icon: Icon(Icons.check),
                            onPressed: () => setState(() {
                              _selectedEffect = null;
                            }),
                          ),
                          Spacer(),
                          
                          // Text('${_selectedEffect!.start.inMinutes.toString().padLeft(2, '0')}.${(_selectedEffect!.start.inSeconds % 60).toString().padLeft(2, '0')}.${(_selectedEffect!.start.inMilliseconds % 1000).toString().padLeft(4, '0')} - ${_selectedEffect!.end.inMinutes.toString().padLeft(2, '0')}.${(_selectedEffect!.end.inSeconds % 60).toString().padLeft(2, '0')}.${(_selectedEffect!.end.inMilliseconds % 1000).toString().padLeft(4, '0')}'),
                          IconButton(
                            icon: Icon(Icons.palette),
                            onPressed: () => {
                              setState(() {_inEffectSettings = true;}),
                              _onColorChanged(_selectedEffect!.getColor(_selectedEffect!.start))
                              },
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () => setState(() {
                              _selectedEffect = null;
                            }),
                          ),
                          
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
                                                onHorizontalDragEnd: (details) => saveData(),
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
                            if (value != "Добавить")
                            setState(() {
                                _selectedEffect = null;
                                _selectedSequence = value!;
                                if (_selectedId != null)
                                  _ledToSequences[_selectedId!] = _selectedSequence;
                            }),
                            _onPositionChanged(_position!),
                            saveData()
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
                                            onPressed: () => showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text("delete?"),
                                                content: Text(sequence),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.of(context).pop(), child: Text("no")),
                                                  TextButton(onPressed: () => {_onSequenceDeleted(sequence), Navigator.of(context).pop()}, child: Text("yes"))
                                                ]
                                              )
                                            ),
                                            icon: Icon(Icons.delete_forever)),
                                      ],
                                    ),
                                  )),
                          ] + [DropdownMenuEntry(value: "Добавить", label: "Добавить",  labelWidget: Row(children: [Text("добавить"), IconButton(onPressed: () => {}, icon: Icon(Icons.add))],))])
                  ],
                ): Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => {
                          },
                          icon: Spacer()
                        ),
                        Spacer(),
                        IconButton(
                          onPressed: () => {
                            setState(() {_inEffectSettings = false;}),
                            _onPositionChanged(_position!)
                          },
                          icon: Icon(Icons.check)
                        ),
                        Spacer(),
                        IconButton(
                            icon: Icon(Icons.copy),
                            onPressed: () => setState(() {
                              _selectedEffect = null;
                            }),
                          ),
                      ],
                    ),
                    _selectedEffect!.settings(_onColorChanged, saveData),
                  ],
                );
              },
            )
          )
        ),
        
      ],
    )
    )
    );
  }
}

void sendPacket(data)  {
   RawDatagramSocket.bind(InternetAddress.anyIPv4, 4210).then((RawDatagramSocket udpSocket) {
    udpSocket.broadcastEnabled = true;
    udpSocket.send(utf8.encode(data), InternetAddress("192.168.43.255"), 4210);
    print("$data sent.");
   });
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

  Widget settings(onColorChanged, onColorChangeEnded) {
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

  Map<String, dynamic> toJson() => {
        'start': start,
        'end': end,
        'color' : color
      };

  @override
  Widget settings(onColorChanged, onColorChangeEnded) {
    return ColorPicker(
      enableShadesSelection: false,
      onColorChanged: (color) => {
        this.color = color,
        onColorChanged(color),
        },
      onColorChangeEnd: (color) => onColorChangeEnded(),
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
  Map<String, List<Led>> strips = {};
  Costume(this.strips);
}

class Led {
  late double x;
  late double y;
  Color color = Colors.black;
  Led(this.x, this.y);

  Led.fromJson(Map<String, dynamic> json)
      : x = json['x'] as double,
        y = json['y'] as double;

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
      };
}

class DataStorage {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<List<String>> getFiles(String directory) async {
    final path = await _localPath;
    final fileList = Directory(path + directory).listSync();
    List<String> stringList = [];
    for (var file in fileList) {
      stringList.add(await (file as File).readAsString());
    }
    return stringList;
  }

  void moveFile() async {
    final path = await _localPath;
    final file = File('$path/costumes/costume 1.json');

    file.deleteSync();
  }

  Future<File> writeData(String data, String route) async {
    final path = await _localPath;
    final file = File('$path/$route');

    return file.writeAsString(data);
  }

  Future<String> readData(String route) async {
    try {
      final path = await _localPath;
      final file = File('$path/$route');

      final contents = await file.readAsString();

      return contents;
    } catch (e) {
      return e.toString();
    }
  }

  void createDirectories() async {
    final path = await _localPath;
    new Directory('$path/patterns').createSync();
    new Directory('$path/costumes').createSync();
    new Directory('$path/audio').createSync();
  }
}