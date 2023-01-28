import 'package:campus_shuttle_flutter/custom_theme.dart';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // const MyApp({Key? key}) : super(key: key); // for old flutter version

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Campus Shuttle',
        home: MyHomePage(),
        darkTheme: customDarkTheme(),
        theme: customLightTheme(),
        themeMode: ThemeMode.dark,
        // themeMode: ThemeMode.system,
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  List<String> stops = ['Blk 1', 'Blk 2', 'Blk 3', 'Blk 4', 'Blk 5', 'Blk 6'];
  String src = 'Blk 1', des = 'Blk 2';
  var currentSrc, currentDes;
  String currentStop = "Blk 1 (Bus stop 1)";
  List<Map<String, dynamic>> data = [];

  bool? check1 = false, check2 = false;

  void setSrc(String? t) {
    src = t ?? stops[0];
    notifyListeners();
  }

  void setDes(String? t) {
    des = t ?? stops[1];
    notifyListeners();
  }

  void setStop(String t) {
    currentStop = t;
    notifyListeners();
  }

  void setCheckbox1(bool? t) {
    check1 = t;
    notifyListeners();
  }

  void setCheckbox2(bool? t) {
    check2 = t;
    notifyListeners();
  }

  // Fetch content from the json file
  void search() async {
    currentSrc = src;
    currentDes = des;

    final String response = await rootBundle.loadString('assets/data.json');
    final jsonData = await json.decode(response);

    data.clear();
    List items = jsonData as List;
    for (Map<String, dynamic> item in items) {
      if (item['src_town'] == currentSrc && item['des_town'] == currentDes) {
        data.add(item);
      }
    }
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
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = DirectionsPage();
        break;
      case 1:
        page = RoutesPage();
        break;
      case 2:
        page = SurveyPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    String getDateTime() {
      var timeNow = DateTime.now();

      return DateFormat('E, d MMM yyyy HH:mm a  ').format(timeNow);
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        appBar: AppBar(
          title: FittedBox(fit: BoxFit.fitWidth, child: Text('Campus Shuttle')),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.access_time_outlined),
              tooltip: 'Show Date and Time',
              onPressed: () {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(getDateTime())));
              },
            ),
          ],
        ),
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                labelType: NavigationRailLabelType.all,
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.directions_bus_filled_outlined),
                    label: Text('Directions'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.map),
                    label: Text('Routes'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.feedback_outlined),
                    label: Text('Survey'),
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
            Expanded(
              child: Container(
                // color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class DirectionsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        const SizedBox(
          height: 18,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('YOUR LOCATION'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton(
                      value: appState.src,
                      items: appState.stops.map((element) {
                        return DropdownMenuItem(
                            value: element, child: Text(element));
                      }).toList(),
                      onChanged: appState.setSrc),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('DESTINATION'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton(
                      value: appState.des,
                      items: appState.stops.map((element) {
                        return DropdownMenuItem(
                            value: element, child: Text(element));
                      }).toList(),
                      onChanged: appState.setDes),
                ),
              ],
            ),
          ],
        ),
        OutlinedButton.icon(
          icon: const Icon(Icons.search, color: Colors.white),
          onPressed: () => {
            appState.search() //do something
          },
          label: const Text(
            'Search',
            // style: TextStyle(color: Colors.white),
          ),
          // style: TextButton.styleFrom(
          //   backgroundColor: Theme.of(context).accentColor,
          // ),
        ),
        const SizedBox(
          height: 12,
        ),
        Expanded(
          child: ListView.builder(
              itemCount: appState.data.length,
              itemBuilder: (context, i) => BusCard(data: appState.data[i])),
        ),
      ],
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    Key? key,
    required this.pair,
  }) : super(key: key);

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
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: pair.asPascalCase,
        ),
      ),
    );
  }
}

class BusCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const BusCard({Key? key, required this.data}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: Colors.blue[700], borderRadius: BorderRadius.circular(12)),
        width: double.infinity,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'YOUR LOCATION',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    Text(
                      // appState.currentSrc,
                      data['src_name']!,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data['src_town']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '→',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 24),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'DESTINATION',
                      style: TextStyle(fontSize: 12, color: Colors.white),
                    ),
                    Text(
                      // appState.currentDes,
                      data['des_name']!,
                      style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      data['des_town']!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 8,
            ),
            Row(
              children: [
                const Icon(
                  Icons.directions,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: Text(
                    data['distance'].toString(),
                    maxLines: 2,
                    // overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                const Icon(
                  Icons.directions_bus,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  data['name']! + ', ' + data['seater'].toString() + ' seater',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            const SizedBox(
              height: 5,
            ),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  data['start_time'].toString(),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(
                  width: 16,
                ),
                const Icon(
                  Icons.timelapse_rounded,
                  color: Colors.white,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(
                  data['duration'].toString(),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoutesPage extends StatelessWidget {
  final List<String> arrivals = <String>['5 mins', '12 mins', '15 mins'];

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
            width: 350,
            height: 280,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: AlignmentDirectional.topStart,
                  child: Image(
                      image: AssetImage('assets/map.png'), fit: BoxFit.fill),
                ),
                Positioned(
                  // top: 150,
                  // bottom: 600,
                  // right: 140,

                  // right: 15, //give the values according to your requirement
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 1',
                    onPressed: () {
                      appState.setStop("Blk 1 (Bus stop 1)");
                    },
                  ),
                ),
                Positioned(
                  left: 168,
                  // right: 100, //give the values according to your requirement
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 2',
                    onPressed: () {
                      appState.setStop("Blk 2 (Bus stop 2)");
                    },
                  ),
                ),
                Positioned(
                  top: 60,
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 3',
                    onPressed: () {
                      appState.setStop("Blk 3 (Bus stop 3)");
                    },
                  ),
                ),
                Positioned(
                  left: 110,
                  top: 60,
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 4',
                    onPressed: () {
                      appState.setStop("Blk 4 (Bus stop 4)");
                    },
                  ),
                ),
                Positioned(
                  left: 80,
                  top: 108,
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 5',
                    onPressed: () {
                      appState.setStop("Blk 5 (Bus stop 5)");
                    },
                  ),
                ),
                Positioned(
                  left: 120,
                  top: 210,
                  child: IconButton(
                    icon: const Icon(
                      Icons.location_pin,
                      color: Colors.blue,
                    ),
                    tooltip: 'Bus stop 6',
                    onPressed: () {
                      appState.setStop("Blk 6 (Bus stop 6)");
                    },
                  ),
                )
              ],
            )),
        Text(
          'Current bus stop: ${appState.currentStop}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.separated(
            itemBuilder: (context, i) => Row(
              children: [
                Expanded(
                  child: Text(
                    "Campus Bus",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                Text(arrivals[i], style: const TextStyle(fontSize: 16)),
              ],
            ),
            separatorBuilder: (context, i) => const Divider(height: 32),
            itemCount: arrivals.length,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          ),
        )
      ],
    );

    ;
  }
}

// Survey //

class SurveyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();

    return Container(
        padding: EdgeInsets.only(top: 20, left: 20, right: 20),
        alignment: Alignment.topLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              //checkbox positioned at left
              checkColor: Colors.white,
              activeColor: Colors.blue,
              value: appState.check1,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                appState.setCheckbox1(value);
              },
              title: Text("I find this app useful!"),
            ),
            CheckboxListTile(
              //checkbox positioned at left
              checkColor: Colors.white,
              activeColor: Colors.blue,
              value: appState.check2,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (bool? value) {
                appState.setCheckbox2(value);
              },
              title: Text("I'm able to find the bus schedule!"),
            ),
            TextField(
                decoration: InputDecoration(
              border: OutlineInputBorder(),
              labelText: 'Any feedback?',
            )),
            OutlinedButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  title: const Text('Confirm submission?'),
                  // content: const Text('AlertDialog description'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'Cancel'),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              ),
              child: const Text('Submit Survey'),
            )
          ],
        ));
  }
}
