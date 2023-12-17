import 'dart:async';
import 'dart:math';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:heart_rate/utils/app_assets.dart';
import 'package:heart_rate/utils/app_colors.dart';
import 'package:heart_rate/widgets/custom_snack_bar.dart';
import 'package:heart_rate/widgets/faded_widget.dart';
import 'package:tflite/tflite.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class HeartRateDisplay extends StatefulWidget {
  const HeartRateDisplay({super.key, this.connectedDevice});

  final BluetoothDevice? connectedDevice;

  @override
  State<HeartRateDisplay> createState() => _HeartRateDisplayState();
}

class _HeartRateDisplayState extends State<HeartRateDisplay> {
  late Timer timer;
  String spo2Text = 'No data';
  String heartRateText = 'No data';
  int spo2Rate = 0;
  int heartRate = 0;

  List<dynamic>? predictionText;

  BluetoothDevice? connectedDevice;

  late FlutterBlue flutterBlue;

  Future<void> _autoConnectToDevice() async {
    try {
      await flutterBlue.startScan();

      await for (ScanResult result in flutterBlue.scan()) {
        if (result.device.id.toString() == 'B9:7E:C4:D4:18') {
          connectedDevice = result.device;
          await connectedDevice!.connect();
          break; // Stop scanning once ESP32 is found
        }
      }

      await flutterBlue.stopScan();
    } catch (e) {
      CustomSnackBar.show(
        context: context,
        message: 'No device is connected',
        state: CustomSnackBarState.error,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    flutterBlue = FlutterBlue.instance;
    _autoConnectToDevice();
    _connectToDevice();
    _loadModel();
    timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _getRandomHeartRate();
    });
  }

  void _getRandomHeartRate() {
    Random random = Random();

    // Generate a random integer between 0 and 300 (inclusive)
    int randomNumber = 0;

    Future.delayed(const Duration(seconds: 10), () {
      setState(() {
        randomNumber = random.nextInt(301);
        heartRate = randomNumber;
        heartRateText = heartRate.toString();
      });
    });
  }

  void _loadModel() async {
    try {
      await Tflite.loadModel(
        model: AppAssets.modelModel,
        labels: AppAssets.modelLabels,
      );
    } catch (e) {
      debugPrint('Error loading TensorFlow Lite model: $e');
    }
  }

  Future<void> _connectToDevice() async {
    List<BluetoothService> services =
        await widget.connectedDevice?.discoverServices() ??
            <BluetoothService>[];

    for (BluetoothService service in services) {
      List<BluetoothCharacteristic> characteristics = service.characteristics;
      for (BluetoothCharacteristic char in characteristics) {
        // Identify the characteristic providing heart rate data
        if (char.uuid == Guid('beb5483e-36e1-4688-b7f5-ea07361b26a')) {
          // Subscribe to heart rate characteristic
          char.setNotifyValue(true);
          char.value.listen((List<int> value) {
            int spo2 = value[0];
            int heartRateResult = value[1];
            setState(() {
              spo2Rate = spo2;
              spo2Text = '$spo2 BPM';
              heartRate = heartRateResult;
              heartRateText = heartRate.toString();
            });
          });
        }
      }
    }
  }

  Uint8List intToUint8List(int value) {
    var byteData = ByteData(4); // Assuming a 32-bit integer
    byteData.setInt32(0, value, Endian.little);
    return byteData.buffer.asUint8List();
  }

  void runInference() async {
    var output = await Tflite.runModelOnBinary(
      binary: intToUint8List(spo2Rate),
    );

    // Process the output and update the UI
    if (output != null && output.isNotEmpty) {
      var label = output[0]['label'];
      setState(() {
        // Update the predictionText based on the label
        predictionText = label;
      });
    }
  }

  @override
  void dispose() {
    // Release resources when the widget is disposed
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          Positioned.fill(
            child: FadedWidget(
              child: Image.asset(
                AppAssets.background,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                    customWidths: CustomSliderWidths(
                      trackWidth: 4,
                      progressBarWidth: 20,
                      shadowWidth: 40,
                    ),
                    customColors: CustomSliderColors(
                      trackColor: Colors.deepOrange,
                      progressBarColor: AppColors.primaryColor,
                      shadowColor: Colors.red.shade800,
                      shadowMaxOpacity: 0.5, //);
                      shadowStep: 20,
                    ),
                    infoProperties: InfoProperties(
                      bottomLabelStyle: const TextStyle(
                        color: AppColors.primaryColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      bottomLabelText: heartRateText,
                      mainLabelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w600,
                      ),
                      modifier: (double value) {
                        return 'Heart Rate';
                      },
                    ),
                    startAngle: 10,
                    angleRange: 360,
                    size: 250.0,
                    animationEnabled: true,
                  ),
                  min: 0,
                  max: 300,
                  initialValue: heartRate.toDouble(),
                ),
                const SizedBox(height: 10),
                SleekCircularSlider(
                  appearance: CircularSliderAppearance(
                    customWidths: CustomSliderWidths(
                      trackWidth: 4,
                      progressBarWidth: 20,
                      shadowWidth: 40,
                    ),
                    customColors: CustomSliderColors(
                      trackColor: Colors.blue.shade200,
                      progressBarColor: Colors.blue,
                      shadowColor: Colors.blue.shade800,
                      shadowMaxOpacity: 0.5, //);
                      shadowStep: 20,
                    ),
                    infoProperties: InfoProperties(
                      bottomLabelStyle: const TextStyle(
                        color: Colors.blue,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                      bottomLabelText: spo2Text,
                      mainLabelStyle: const TextStyle(
                        color: Colors.white,
                        fontSize: 25.0,
                        fontWeight: FontWeight.w600,
                      ),
                      modifier: (double value) {
                        return 'SPO2';
                      },
                    ),
                    startAngle: 10,
                    angleRange: 360,
                    size: 250.0,
                    animationEnabled: true,
                  ),
                  min: 0,
                  max: 100,
                  initialValue: spo2Rate.toDouble(),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () => runInference(),
                  style: ButtonStyle(
                    backgroundColor:
                        MaterialStateProperty.all(AppColors.primaryColor),
                  ),
                  child: const Text(
                    'Run Inference',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                predictionText != null
                    ? AnimatedTextKit(
                        isRepeatingAnimation: false,
                        animatedTexts: [
                          TyperAnimatedText(
                            '${predictionText![0]["label"]}',
                            textAlign: TextAlign.center,
                            speed: const Duration(milliseconds: 100),
                            textStyle: const TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 25.0,
                            ),
                          ),
                        ],
                      )
                    : const Text(''),
              ],
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text(
        'Heart Rate',
        style: TextStyle(
          fontSize: 25,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
