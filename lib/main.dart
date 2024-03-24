import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_audio_waveforms/flutter_audio_waveforms.dart';
import 'package:flutter/services.dart';
import 'package:just_waveform/just_waveform.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';
import 'package:path_provider/path_provider.dart';

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

  List<Color> _colors = List<Color>.filled(_costume.length, Color.fromARGB(255, 245, 153, 153));

  int? _selectedId;
  double _multiplier = 1.0;
  double _previousMultiplier = 1.0;
  Offset? _scaleOrigin = Offset.zero;
  double _positionX = 0.0;


  final progressStream = BehaviorSubject<WaveformProgress>();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {

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

  static const _costume = {0: [100, 100], 1: [200, 100]};

  void _onLedTapped(int index) {
    setState(() {
      _selectedId = index;
    });
  }

  void _onWidthChanged(ScaleUpdateDetails details) {
    if (details.pointerCount == 2)
    setState(() {
      _multiplier = details.horizontalScale * _previousMultiplier;
    });
    
    else if (details.pointerCount == 1)
    setState(() {
      _positionX = _positionX + details.focalPointDelta.dx / _multiplier;
    });
    print(_positionX);
  }

  void _onScaleStarted(ScaleStartDetails details) {
    // if (details.pointerCount > 1)
    // setState(() {
    //   _scaleOrigin = details.localFocalPoint;
    // });

  }

  void _onScaleEnded() {
    setState(() {
      _previousMultiplier = _multiplier;
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
            height: 400,
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
                    child: Text(
                      '${(100 * progress).toInt()}%',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  );
                }

                return  Column(
                  children: [
                    GestureDetector(
                      onScaleUpdate: (event) => _onWidthChanged(event),
                      onScaleEnd: (event) => _onScaleEnded(),
                      onScaleStart: (event) => _onScaleStarted(event),
                      child: Container(
                        decoration: BoxDecoration(border: Border.all(width: 1.0, color:  Colors.red)),
                        child: Transform.scale(
                          scaleX: max(_multiplier, 1.0),
                          origin: _scaleOrigin,
                          child: Transform.translate(
                            offset: Offset(_positionX, 0.0),
                            child: PolygonWaveform(
                              samples: waveform.data.map((e) => e.toDouble()).toList(),
                              absolute: true,
                              inactiveColor: Color(0xffcccccc),
                              height: 100,
                              width: MediaQuery.of(context).size.width,
                            ),
                          ),
                        ),
                      ),
                    ),
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