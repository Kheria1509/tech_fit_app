import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../utils/app_constants.dart';
import '../widgets/app_button.dart';

class BluetoothDeviceScreen extends StatefulWidget {
  const BluetoothDeviceScreen({Key? key}) : super(key: key);

  @override
  State<BluetoothDeviceScreen> createState() => _BluetoothDeviceScreenState();
}

class _BluetoothDeviceScreenState extends State<BluetoothDeviceScreen> {
  List<ScanResult> devices = [];
  bool isScanning = false;
  BluetoothDevice? connectedDevice;

  @override
  void initState() {
    super.initState();
    // Check if Bluetooth is available and enabled
    checkBluetoothStatus();
  }

  void checkBluetoothStatus() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Bluetooth Not Supported'),
                content: const Text('This device does not support Bluetooth.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              );
            },
          );
        }
        return;
      }

      // Check if Bluetooth is turned on
      if (await FlutterBluePlus.isOn == false) {
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Bluetooth is Off'),
                content: const Text('Please enable Bluetooth to continue.'),
                actions: [
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      // Try to turn on Bluetooth
                      try {
                        await FlutterBluePlus.turnOn();
                      } catch (e) {
                        // Handle the case where we can't turn on Bluetooth
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please enable Bluetooth manually'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Enable'),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error checking Bluetooth status: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void startScan() async {
    setState(() {
      devices.clear();
      isScanning = true;
    });

    try {
      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        setState(() {
          devices = results;
        });
      });

      // When scan completes
      await Future.delayed(const Duration(seconds: 4));
      if (mounted) {
        setState(() {
          isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect();
      setState(() {
        connectedDevice = device;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected to ${device.platformName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to connect: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void startSession() {
    Navigator.pushNamed(context, '/device_tracking');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Connect Device'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Connect to Device',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please connect to your fitness device to start tracking',
                style: TextStyle(fontSize: 16, color: AppColors.textLight),
              ),
              const SizedBox(height: 24),

              // Scan button
              AppButton(
                text: isScanning ? 'Scanning...' : 'Scan for Devices',
                onPressed: isScanning ? () {} : startScan,
              ),
              const SizedBox(height: 24),

              // Device list
              Expanded(
                child:
                    devices.isEmpty
                        ? Center(
                          child: Text(
                            isScanning
                                ? 'Scanning for devices...'
                                : 'No devices found',
                            style: const TextStyle(color: AppColors.textLight),
                          ),
                        )
                        : ListView.builder(
                          itemCount: devices.length,
                          itemBuilder: (context, index) {
                            final device = devices[index].device;
                            final isConnected = connectedDevice == device;

                            return Card(
                              child: ListTile(
                                title: Text(
                                  device.platformName.isEmpty
                                      ? 'Unknown Device'
                                      : device.platformName,
                                ),
                                subtitle: Text(device.remoteId.str),
                                trailing:
                                    isConnected
                                        ? const Icon(
                                          Icons.bluetooth_connected,
                                          color: Colors.green,
                                        )
                                        : const Icon(Icons.bluetooth),
                                onTap:
                                    isConnected
                                        ? null
                                        : () => connectToDevice(device),
                              ),
                            );
                          },
                        ),
              ),

              // Start Session button (only visible when device is connected)
              if (connectedDevice != null) ...[
                const SizedBox(height: 24),
                AppButton(text: 'Start Session', onPressed: startSession),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Disconnect from device when leaving the screen
    if (connectedDevice != null) {
      connectedDevice!.disconnect();
    }
    super.dispose();
  }
}
