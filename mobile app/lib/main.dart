import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iot/util/smart_device.dart';
import 'package:iot/util/MQTThandler.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Thông tin tài khoản Adafruit IO

  MqttHandler mqttHandler = MqttHandler();
  double temperature = 25.5;
  double humidity = 60.0;

  List mySmartDevices = [
    // [ smartDeviceName, iconPath , powerStatus ]
    ["Smart Light", "lib/icons/light-bulb.png", true],
    ["Smart AC", "lib/icons/air-conditioner.png", false],
    ["Smart TV", "lib/icons/smart-tv.png", false],
    ["Smart Fan", "lib/icons/fan.png", false],
  ];

  void powerSwitchChanged(bool value, int index) {
    if (index == 0) {
      int a = value ? 1 : 0;
      mqttHandler.publishMessage("GutD/feeds/light", a.toString());
    }else if (index == 1) {
      int a = value ? 1 : 0;
      mqttHandler.publishMessage("GutD/feeds/ac", a.toString());
    }else if (index == 2) {
      int a = value ? 1 : 0;
      mqttHandler.publishMessage("GutD/feeds/tv", a.toString());
    }else if (index == 3) {
      int a = value ? 1 : 0;
      mqttHandler.publishMessage("GutD/feeds/fan", a.toString());
    }
    setState(() {
      mySmartDevices[index][2] = value;
    });
  }

  Future<double> fetchData(String feed) async {
    final response = await http
        .get(Uri.parse('https://io.adafruit.com/api/v2/GutD/feeds/$feed'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final value = double.parse(jsonData['last_value']);
      return value;
    } else {
      throw Exception('Failed to load temperature data');
    }
  }

  Future<void> init() async {
    final double light = await fetchData('light');
    final double ac = await fetchData('ac');
    final double tv = await fetchData('tv');
    final double fan = await fetchData('fan');
    setState(() {
      mySmartDevices[0][2] = light == 1 ? true : false;
      mySmartDevices[1][2] = ac == 1 ? true : false;
      mySmartDevices[2][2] = tv == 1 ? true : false;
      mySmartDevices[3][2] = fan == 1 ? true : false;
    });
  }

  @override
  void initState() {
    super.initState();
    mqttHandler.connect();
    init();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.grey.shade200,
        appBar: AppBar(
          title: Row(
            children: [
              Image.asset(
                'lib/icons/home.png',
                width: 40,
                height: 40,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                'Home',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            ],
          ),
          backgroundColor: Colors.grey.shade200,
        ),
        body: SafeArea(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color.fromARGB(44, 14, 25, 105),
                  ),
                  height: 90,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0, top: 23),
                            child: Image.asset(
                              'lib/icons/humidity.png',
                              width: 40,
                              height: 40,
                            )
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(left: 25.0, top: 29),
                              child: ValueListenableBuilder(
                                valueListenable: mqttHandler.humi,
                                builder: (BuildContext context, String value,
                                    Widget? child) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Text(
                                        'Độ ẩm: $value %',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      )
                                    ],
                                  );
                                },
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    color: const Color.fromARGB(44, 14, 25, 105),
                  ),
                  height: 90,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 25.0, top: 23),
                            child: Image.asset(
                              'lib/icons/temperature.png',
                              width: 40,
                              height: 40,
                            )
                          ),
                          Padding(
                              padding:
                                  const EdgeInsets.only(left: 25.0, top: 29),
                              child: ValueListenableBuilder(
                                valueListenable: mqttHandler.temp,
                                builder: (BuildContext context, String value,
                                    Widget? child) {
                                  return Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: <Widget>[
                                      Text(
                                        'Nhiệt độ: $value °C',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      )
                                    ],
                                  );
                                },
                              )),
                        ],
                      )
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: GridView.builder(
                  itemCount: 4,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 25),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1 / 1.3,
                  ),
                  itemBuilder: (context, index) {
                    return SmartDeviceBox(
                      smartDeviceName: mySmartDevices[index][0],
                      iconPath: mySmartDevices[index][1],
                      powerOn: mySmartDevices[index][2],
                      onChanged: (value) => powerSwitchChanged(value, index),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ImageSection extends StatelessWidget {
  const ImageSection({super.key, required this.image});

  final String image;

  @override
  Widget build(BuildContext context) {
    // #docregion Image-asset
    return Image.asset(
      image,
      width: 600,
      height: 240,
      fit: BoxFit.cover,
    );
    // #enddocregion Image-asset
  }
}
