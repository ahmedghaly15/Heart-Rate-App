import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:heart_rate/screens/bluetooth_off_screen.dart';
import 'package:heart_rate/screens/heart_rate_display.dart';
import 'package:permission_handler/permission_handler.dart';

class EntryPointScreen extends StatefulWidget {
  const EntryPointScreen({super.key});

  @override
  State<EntryPointScreen> createState() => _EntryPointScreenState();
}

class _EntryPointScreenState extends State<EntryPointScreen> {
  Future<void> _askForPermission() async {
    var status = await Permission.bluetoothScan.status;
    if (status.isDenied) {
      await Permission.bluetooth.request();
      await Permission.bluetoothConnect.request();
      await Permission.bluetoothScan.request();
    }
  }

  @override
  void initState() {
    _askForPermission();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<BluetoothState>(
      stream: FlutterBlue.instance.state,
      initialData: BluetoothState.unknown,
      builder: (c, snapshot) {
        final state = snapshot.data;
        if (state == BluetoothState.on) {
          return const HeartRateDisplay();
        }
        return BluetoothOffScreen(state: state!);
      },
    );
  }
}
