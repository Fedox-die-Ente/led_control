import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ir_encoder.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.white),
        ),
      ),
      home: const LedRemoteScreen(),
    );
  }
}

class LedRemoteScreen extends StatefulWidget {
  const LedRemoteScreen({super.key});

  @override
  State<LedRemoteScreen> createState() => _LedRemoteScreenState();
}

class _LedRemoteScreenState extends State<LedRemoteScreen> with TickerProviderStateMixin {
  String status = "Warte auf Befehl...";
  late AnimationController _pulseController = AnimationController(vsync: this);
  late AnimationController _rippleController = AnimationController(vsync: this);
  Offset? _ripplePosition;
  int _commandCount = 0;
  bool _hapticEnabled = true;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _rippleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rippleController.dispose();
    super.dispose();
  }

  Future<void> _sendSignal(String label, List<int> signal, {Color? color}) async {
    if (_hapticEnabled) {
      HapticFeedback.mediumImpact();
    }

    setState(() {
      status = "⚡ Sende $label ...";
      _commandCount++;
    });

    try {
      await IrSignals.sendSignal(signal);
      
      if (_hapticEnabled) {
        HapticFeedback.lightImpact();
      }

      setState(() {
        status = _getSuccessMessage(label);
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => status = "Warte auf Befehl...");
        }
      });
    } catch (e) {
      if (_hapticEnabled) {
        HapticFeedback.heavyImpact();
      }
      setState(() => status = "❌ Fehler: $e");
    }
  }

  String _getSuccessMessage(String label) {
    final messages = [
      "🎉 $label gesendet!",
    ];
    return messages[_commandCount % messages.length];
  }

  void _showRipple(Offset position) {
    setState(() => _ripplePosition = position);
    _rippleController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xff667eea), Color(0xff764ba2)],
              ),
            ),
          ),
          
          if (_ripplePosition != null)
            CustomPaint(
              painter: RipplePainter(
                animation: _rippleController,
                position: _ripplePosition!,
              ),
              child: Container(),
            ),

          Center(
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                final scale = 1.0 + (_pulseController.value * 0.02);
                return Transform.scale(
                  scale: scale,
                  child: child,
                );
              },
              child: Container(
                width: size.width * 0.8,
                height: size.height * 0.7,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white24,
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Florian's LED Controller",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() => _hapticEnabled = !_hapticEnabled);
                            HapticFeedback.selectionClick();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _hapticEnabled ? Colors.white24 : Colors.white12,
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _hapticEnabled ? Icons.vibration : Icons.phonelink_erase,
                                  size: 14,
                                  color: Colors.white70,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _hapticEnabled ? "Vibration AN" : "Vibration AUS",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "+",
                          icon: Icons.arrow_upward,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Heller", IrSignals.increaseBrightness);
                          },
                        ),
                        RemoteButtonData(
                          label: "-",
                          icon: Icons.arrow_downward,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Dunkler", IrSignals.decreaseBrightness);
                          },
                        ),
                        RemoteButtonData(
                          label: "OFF",
                          icon: Icons.power_settings_new,
                          gradient: const [Color(0xff434343), Color(0xff1a1a1a)],
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("OFF", IrSignals.off);
                          },
                        ),
                        RemoteButtonData(
                          label: "ON",
                          icon: Icons.power_settings_new,
                          gradient: const [Color(0xff4CAF50), Color(0xff2E7D32)],
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("ON", IrSignals.on);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "R",
                          singleColor: Colors.red,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Rot", IrSignals.red, color: Colors.red);
                          },
                        ),
                        RemoteButtonData(
                          label: "G",
                          singleColor: Colors.green,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Grün", IrSignals.green, color: Colors.green);
                          },
                        ),
                        RemoteButtonData(
                          label: "B",
                          singleColor: Colors.blue.shade900,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Blau", IrSignals.blue, color: Colors.blue);
                          },
                        ),
                        RemoteButtonData(
                          label: "W",
                          gradient: const [Color(0xffFFFFFF), Color(0xffCCCCCC)],
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Weiß", IrSignals.white);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xffF75644),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Hell-Rot", IrSignals.lighterRed);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff4BB964),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Hell-Grün", IrSignals.lighterGreen);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff2E96DD),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Hell-Blau", IrSignals.lighterBlue);
                          },
                        ),
                        RemoteButtonData(
                          label: "FLSH",
                          icon: Icons.flash_on,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Blitz", IrSignals.flash);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xffBD2F05),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Dunkel-Orange", IrSignals.darkOrange);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff429A93),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Teal", IrSignals.teal);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color.fromARGB(255, 77, 42, 119),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Dunkel-Lila", IrSignals.darkPurple);
                          },
                        ),
                        RemoteButtonData(
                          label: "STRB",
                          icon: Icons.electrical_services,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Strobe", IrSignals.strobe);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xffCC7803),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Gelb", IrSignals.orange);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff00697D),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Cyan", IrSignals.cyan);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff541945),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Lila", IrSignals.purple);
                          },
                        ),
                        RemoteButtonData(
                          label: "FADE",
                          icon: Icons.gradient,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Fade", IrSignals.fade);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    ButtonRow(
                      buttons: [
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xffBFB402),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Gelb", IrSignals.yellow);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xff006094),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Weiteres Blau", IrSignals.anotherBlue);
                          },
                        ),
                        RemoteButtonData(
                          label: "",
                          singleColor: const Color(0xffA10F75),
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Pink", IrSignals.pink);
                          },
                        ),
                        RemoteButtonData(
                          label: "SMTH",
                          icon: Icons.water_drop,
                          onTap: (position) {
                            _showRipple(position);
                            _sendSignal("Smooth", IrSignals.smooth);
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RipplePainter extends CustomPainter {
  final Animation<double> animation;
  final Offset position;

  RipplePainter({required this.animation, required this.position})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    if (animation.value > 0) {
      final paint = Paint()
        ..color = Colors.white.withOpacity(0.3 * (1 - animation.value))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      canvas.drawCircle(
        position,
        50 * animation.value,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(RipplePainter oldDelegate) => true;
}

class ButtonRow extends StatelessWidget {
  final List<RemoteButtonData> buttons;
  final double spacing;

  const ButtonRow({
    super.key,
    required this.buttons,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons
          .map((b) => Padding(
                padding: EdgeInsets.symmetric(horizontal: spacing / 2),
                child: RemoteButton(data: b),
              ))
          .toList(),
    );
  }
}

class RemoteButtonData {
  final String label;
  final List<Color>? gradient;
  final Color? singleColor;
  final IconData? icon;
  final Function(Offset)? onTap;

  const RemoteButtonData({
    required this.label,
    this.onTap,
    this.singleColor,
    this.gradient,
    this.icon,
  });
}

class RemoteButton extends StatefulWidget {
  final RemoteButtonData data;

  const RemoteButton({super.key, required this.data});

  @override
  State<RemoteButton> createState() => _RemoteButtonState();
}

class _RemoteButtonState extends State<RemoteButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final defaultGradient = const [Color(0xff434343), Color(0xff2d2d2d)];

    BoxDecoration decoration;
    if (widget.data.singleColor != null) {
      decoration = BoxDecoration(
        color: widget.data.singleColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: _isPressed
            ? []
            : [
                BoxShadow(
                  color: widget.data.singleColor!.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
      );
    } else if (widget.data.gradient != null && widget.data.gradient!.isNotEmpty) {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.data.gradient!,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: _isPressed
            ? []
            : const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
      );
    } else {
      decoration = BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: defaultGradient,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24, width: 1),
        boxShadow: _isPressed
            ? []
            : const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
      );
    }

    return GestureDetector(
      onTapDown: (details) {
        setState(() => _isPressed = true);
        _controller.forward();
      },
      onTapUp: (details) {
        setState(() => _isPressed = false);
        _controller.reverse();
        if (widget.data.onTap != null) {
          final RenderBox box = context.findRenderObject() as RenderBox;
          final position = box.localToGlobal(Offset.zero) + box.size.center(Offset.zero);
          widget.data.onTap!(position);
        }
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _controller.reverse();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final scale = 1.0 - (_controller.value * 0.1);
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 55,
              height: 45,
              alignment: Alignment.center,
              decoration: decoration,
              child: widget.data.icon != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.data.icon,
                          color: _getTextColor(),
                          size: 18,
                        ),
                        if (widget.data.label.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.data.label,
                            style: TextStyle(
                              color: _getTextColor(),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    )
                  : Text(
                      widget.data.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _getTextColor(),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }

  Color _getTextColor() {
    if (widget.data.singleColor == Colors.white ||
        widget.data.gradient?.first == const Color(0xffFFFFFF)) {
      return Colors.black87;
    }
    return Colors.white;
  }
}