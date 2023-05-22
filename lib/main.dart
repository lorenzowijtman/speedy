import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:location/location.dart';
// import 'package:geolocator/geolocator.dart' as geo;
import 'package:permission_handler/permission_handler.dart' as perm;
import 'package:volume_control/volume_control.dart';
// import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const VolumeControlPage(),
    );
  }
}

class VolumeControlPage extends StatefulWidget {
  const VolumeControlPage({super.key});
  @override
  State<VolumeControlPage> createState() => _VolumeControlPageState();
}

class _VolumeControlPageState extends State<VolumeControlPage> {
  double _currentSpeed = 0.0;
  double _trackSpeed = 0.0;
  double _currentVolume = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeVolumeControl();
    _startListeningToSpeedChanges();
  }

  void _initializeVolumeControl() async {
    double volume = await VolumeControl.volume;
    setState(() {
      _currentVolume = volume;
    });
  }

  void _startListeningToSpeedChanges() async {
    perm.PermissionStatus permissionStatus =
        await perm.Permission.locationWhenInUse.request();
    if (permissionStatus == perm.PermissionStatus.granted) {
      // Request always permission
      permissionStatus = await perm.Permission.locationAlways.request();

      if (permissionStatus == perm.PermissionStatus.granted) {
        // if (defaultTargetPlatform == TargetPlatform.android) {
        // var l = geo.AndroidSettings(
        //     accuracy: geo.LocationAccuracy.high,
        //     distanceFilter: 100,
        //     forceLocationManager: true,
        //     intervalDuration: const Duration(seconds: 3),
        //     //(Optional) Set foreground notification config to keep the app alive
        //     //when going to the background
        //     foregroundNotificationConfig:
        //         const geo.ForegroundNotificationConfig(
        //       notificationText:
        //           "Example app will continue to receive your location even when you aren't using it",
        //       notificationTitle: "Running in Background",
        //       enableWakeLock: false,
        //     ));
// }

        Location location = Location();

        location.enableBackgroundMode(enable: true);

        location.onLocationChanged.listen((LocationData currentLocation) {
          // Use current location
          print(
              'Speed: ${currentLocation.speed}, accuracy: ${currentLocation.speedAccuracy}');

          // TODO ADD ALLOW_START_FOREGROUND, reload app when it's in the background

          double? speed = currentLocation.speed ?? 0;

          setState(() {
            _currentSpeed = speed;
          });

          if (speed < 150) {
            if (_trackSpeed + 20 < speed) {
              // Adjust volume up
              setState(() {
                _trackSpeed = speed;
              });
              _adjustVolumeBasedOnSpeed(speed);
            } else if (_trackSpeed + 20 > speed) {
              // Adjust volume down
              setState(() {
                _trackSpeed = speed;
              });
              _adjustVolumeBasedOnSpeed(speed);
            }
          }
        });

        // var accuracy = await geo.Geolocator.getLocationAccuracy();
        // print(accuracy);
        // geo.Geolocator.getPositionStream().listen((geo.Position position) {
        //   print('speed! ${position.speed}');
        //   double speed = position.speed;

        //   setState(() {
        //     _currentSpeed = speed;
        //   });

        //   if (speed < 150) {
        //     if (_trackSpeed + 20 < speed) {
        //       // Adjust volume up
        //       setState(() {
        //         _trackSpeed = speed;
        //       });
        //       _adjustVolumeBasedOnSpeed(speed);
        //     } else if (_trackSpeed + 20 > speed) {
        //       // Adjust volume down
        //       setState(() {
        //         _trackSpeed = speed;
        //       });
        //       _adjustVolumeBasedOnSpeed(speed);
        //     }
        //   }
        // });
      }
    } else {
      // Handle the case when location permission is not granted
      print('no :()');
    }
  }

  void _adjustVolumeBasedOnSpeed(double speed) async {
    // Define your own logic to adjust the volume based on speed
    double maxSpeed = 150.0; // Maximum speed at which volume is increased
    double maxVolume = 0.8; // Maximum volume level

    double newVolume =
        speed <= maxSpeed ? (speed / maxSpeed) * maxVolume : maxVolume;

    await VolumeControl.setVolume(newVolume);
    setState(() {
      _currentVolume = newVolume;
    });
  }

  double _val = 0.5;
  Timer? timer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Volume Control'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current Speed: $_currentSpeed m/s',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 20),
            Text(
              'Current Volume: $_currentVolume',
              style: const TextStyle(fontSize: 20),
            ),
            Center(
                child: Slider(
                    value: _val,
                    min: 0,
                    max: 1,
                    divisions: 100,
                    onChanged: (val) {
                      _val = val;
                      setState(() {});
                      if (timer != null) {
                        timer?.cancel();
                      }

                      //use timer for the smoother sliding
                      timer = Timer(const Duration(milliseconds: 200), () {
                        setState(() {
                          _currentVolume = val;
                        });
                        VolumeControl.setVolume(val);
                      });
                    })),
          ],
        ),
      ),
    );
  }
}
