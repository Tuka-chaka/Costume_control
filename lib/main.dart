import 'package:flutter/material.dart';
import 'package:audio_waveforms/audio_waveforms.dart';

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

  PlayerController controller = PlayerController(); 

  static const _costume = {0: [100, 100], 1: [200, 100]};

  void _onLedTapped(int index) {
    setState(() {
      _selectedId = index;
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
            child: GestureDetector(
              child: _selectedId == null ? 
                  AudioFileWaveforms(
                    size: Size(MediaQuery.of(context).size.width, 100.0),
                    playerController: controller,
                    enableSeekGesture: true,
                    waveformType: WaveformType.long,
                    waveformData: [],
                    playerWaveStyle: const PlayerWaveStyle(
                      fixedWaveColor: Colors.white54,
                      liveWaveColor: Colors.blueAccent,
                      spacing: 6,
                    ),
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
  print("$data sent.");}