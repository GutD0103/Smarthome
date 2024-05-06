import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MqttHandler with ChangeNotifier {
  final ValueNotifier<String> temp = ValueNotifier<String>("");
  final ValueNotifier<String> humi = ValueNotifier<String>("");
  final MqttServerClient client =
      MqttServerClient.withPort('io.adafruit.com', 'GutD', 1883);
  final String ioUsername = "GutD";
  final String ioKey = "aio_HfJT236l1hBdOaGxjsUEbl5B7uXI";
  Future<Object> connect() async {
    client.logging(on: false);
    client.onConnected = onConnected;
    client.onDisconnected = onDisconnected;
    client.onUnsubscribed = onUnsubscribed;
    client.onSubscribed = onSubscribed;
    client.onSubscribeFail = onSubscribeFail;
    client.pongCallback = pong;
    client.keepAlivePeriod = 60;

    humi.value = await getData('humidity');
    temp.value = await getData('temperature');

    /// Set the correct MQTT protocol for mosquito
    client.setProtocolV311();

    final connMessage = MqttConnectMessage()
        .withWillTopic('willtopic')
        .withWillMessage('Will message')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    print('MQTT_LOGS::Mosquitto client connecting....');

    client.connectionMessage = connMessage;
    try {
      await client.connect(ioUsername, ioKey);
    } catch (e) {
      print('Exception: $e');
      client.disconnect();
    }

    if (client.connectionStatus!.state == MqttConnectionState.connected) {
      print('MQTT_LOGS::Mosquitto client connected');
    } else {
      print(
          'MQTT_LOGS::ERROR Mosquitto client connection failed - disconnecting, status is ${client.connectionStatus}');
      client.disconnect();
      return -1;
    }

    print('MQTT_LOGS::Subscribing to the test/lol topic');
    const topics = ['GutD/feeds/humidity', 'GutD/feeds/temperature','GutD/feeds/tv','GutD/feeds/ac','GutD/feeds/light','GutD/feeds/fan'];
    for (var topic in topics) {
      client.subscribe(topic, MqttQos.atMostOnce);
    }

    client.updates!.listen((List<MqttReceivedMessage<MqttMessage?>>? c) {
      final recMess = c![0].payload as MqttPublishMessage;
      final pt =
          MqttPublishPayload.bytesToStringAsString(recMess.payload.message);

      if (c[0].topic == 'GutD/feeds/humidity') {
        humi.value = pt;
      } else if (c[0].topic == 'GutD/feeds/temperature') {
        temp.value = pt;
      }

      notifyListeners();
      print(
          'MQTT_LOGS:: New data arrived: topic is <${c[0].topic}>, payload is ${pt}');
      print('');
    });

    return client;
  }

  Future<String> getData(String mytopic) async {
    final response = await http
        .get(Uri.parse('https://io.adafruit.com/api/v2/GutD/feeds/${mytopic}'));

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final value = jsonData['last_value'];
      return value;
    } else {
      throw Exception('Failed to load temperature data');
    }
  }

  void onConnected() {
    print('MQTT_LOGS:: Connected');
  }

  void onDisconnected() {
    print('MQTT_LOGS:: Disconnected');
  }

  void onSubscribed(String topic) {
    print('MQTT_LOGS:: Subscribed topic: $topic');
  }

  void onSubscribeFail(String topic) {
    print('MQTT_LOGS:: Failed to subscribe $topic');
  }

  void onUnsubscribed(String? topic) {
    print('MQTT_LOGS:: Unsubscribed topic: $topic');
  }

  void pong() {
    print('MQTT_LOGS:: Ping response client callback invoked');
  }

  void publishMessage(String feed,String message) {
    final builder = MqttClientPayloadBuilder();
    builder.addString(message);

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      client.publishMessage(feed, MqttQos.atMostOnce, builder.payload!);
    }
  }
}
