import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:torch_light/torch_light.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

class Flash_Bulb extends StatefulWidget {
  const Flash_Bulb({
    super.key,
  });

  @override
  State<Flash_Bulb> createState() => _Flash_BulbState();
}

class _Flash_BulbState extends State<Flash_Bulb>
    with SingleTickerProviderStateMixin {
  final _springDescription =
      SpringDescription(mass: 1.0, stiffness: 500.0, damping: 15.0);
  // for Spring Simulation at X axis
  late SpringSimulation _springSimX;
  // for Spring Simulation at Y axis
  late SpringSimulation _springSimY;
  //For smooth execution of animations
  Ticker? _ticker;
  // For Thumb position
  Offset thumboffsets = Offset(0, 100.0);
  // For Anchor Position
  Offset anchoroffsets = Offset.zero;
  // For State change
  bool _states = false;
  // For Audio play
  final player = AudioPlayer();
  // audio
  void play() async {
    print("music played");
    await player.play(DeviceFileSource('assets/audio/classic-click.mp3'));
  }

  // function for turning On FlashLight
  Future<void> torch_light_on() async {
    try {
      await TorchLight.enableTorch();
      print("Turn On");
    } catch (e) {
      print("Error: ${e}");
    } on EnableTorchNotAvailableException catch (error) {
      var snackBar = SnackBar(content: Text("Error: ${error}"));
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  // Function for turning Off FlashLight
  Future<void> torch_light_off() async {
    try {
      await TorchLight.disableTorch();
      print("Turn Off");
    } catch (e) {
      print("Error: ${e}");
    }
  }

  // when anchor is stretch
  void _onpanStart(DragStartDetails details) {
    endSpring();
  }

  // Update between the event
  void _onpanupdate(DragUpdateDetails details) {
    setState(() {
      thumboffsets += details.delta;
    });
  }

  // When Anchor is Stretch off
  void _onPanEnd(DragEndDetails details) {
    StartSpring();
    setState(() {
      if (thumboffsets.dy >= 0.0) {
        print("${thumboffsets.dy}");
        _states != false ? torch_light_off() : torch_light_on();
        _states = !_states;
        _states == false ? play() : play();
      }
    });
  }

  // When Spring return to orignal Position
  void endSpring() {
    if (_ticker != null) {
      _ticker!.stop();
    }
  }

  // When Spring is Start
  void StartSpring() {
    _springSimX = SpringSimulation(
        _springDescription, thumboffsets.dx, anchoroffsets.dx, 0);

    _springSimY =
        SpringSimulation(_springDescription, thumboffsets.dy, 100, 100);

    if (_ticker == null) {
      _ticker ??= createTicker(_onTick);
    }
    _ticker!.start();
  }

  void _onTick(Duration elapsedTime) {
    final elapsedSecondFraction = elapsedTime.inMilliseconds / 1000.0;
    setState(() {
      thumboffsets = Offset(_springSimX.x(elapsedSecondFraction),
          _springSimY.x(elapsedSecondFraction));
    });

    if (_springSimY.isDone(elapsedSecondFraction) &&
        _springSimX.isDone(elapsedSecondFraction)) {
      endSpring();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (anchoroffsets == null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        RenderBox _box = context.findRenderObject() as RenderBox;
        if (_box != null && _box.hasSize) {
          setState(() {
            anchoroffsets = _box.size.center(Offset.zero);
            thumboffsets = anchoroffsets;
          });
        }
      });
      return SizedBox();
    }
    return PopScope(
      canPop: _states != true,
      child: Scaffold(
          backgroundColor: _states != true
              ? Color.fromRGBO(247, 247, 247, 1)
              : Color.fromRGBO(255, 224, 125, 1),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                GestureDetector(
                  onPanStart: _onpanStart,
                  onPanUpdate: _onpanupdate,
                  onPanEnd: _onPanEnd,
                  // Stack is used here
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background Container With Color
                      Container(
                        color: _states != true
                            ? Color.fromRGBO(247, 247, 247, 1)
                            : Color.fromRGBO(255, 224, 125, 1),
                        width: 400,
                        height: 700,
                      ),
                      // Position of Text
                      Positioned(
                          top: 100,
                          child: Text(
                            "Flash Bulb",
                            style: GoogleFonts.lemon(
                                fontSize: 22,
                                color: _states != true
                                    ? Color.fromRGBO(255, 224, 125, 1)
                                    : Color.fromRGBO(226, 223, 226, 1)),
                          )),
                      // Position of image
                      Positioned(
                          top: 250,
                          child: _states != true
                              ? Image.asset(
                                  'assets/images/light-bulb-grey-128px.png',
                                  height: 100,
                                )
                              : Image.asset(
                                  'assets/images/light-bulb-on-128px.png',
                                  height: 100,
                                )),
                      // Position of image
                      Positioned(
                        top: 345,
                        child: CustomPaint(
                          foregroundPainter: pull_rope(
                            _states != true
                                ? Color.fromRGBO(148, 145, 145, 1)
                                : Color.fromRGBO(110, 96, 184, 1),
                            AnchorOffset: anchoroffsets,
                            SpringOffset: thumboffsets,
                          ),
                        ),
                      ),
                      // Position of knot
                      Positioned(
                        top: 335,
                        child: Transform.translate(
                          offset: thumboffsets,
                          child: Icon(
                            Icons.circle,
                            size: 14,
                            color: _states != true
                                ? Color.fromRGBO(148, 145, 145, 1)
                                : Color.fromRGBO(110, 96, 184, 1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 60,
                ),
                // Last Text
                Text(
                  "Design & Build by Ahmad Nasir",
                  style: GoogleFonts.lemon(
                      fontSize: 12,
                      color: _states != true
                          ? Color.fromRGBO(255, 224, 125, 1)
                          : Color.fromRGBO(255, 234, 200, 1)),
                ),
              ],
            ),
          )),
    );
  }
}

// Drawn Line here
class pull_rope extends CustomPainter {
  final Offset SpringOffset;

  final Color line_color;
  final Offset AnchorOffset;
  pull_rope(this.line_color,
      {required this.AnchorOffset, required this.SpringOffset});

  @override
  void paint(Canvas canvas, Size size) {
    final line_paint = Paint()
      ..color = line_color
      ..strokeWidth = 3;
    final _center = size.center(Offset.zero);
    canvas.drawLine(AnchorOffset, SpringOffset, line_paint);

    // TODO: implement paint
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
