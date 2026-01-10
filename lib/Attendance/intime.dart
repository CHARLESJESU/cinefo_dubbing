import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'dailogei.dart';
import 'nfcnotifier.dart';

class IntimeScreen extends StatelessWidget {
  const IntimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Set attendance status for In Time
    return ChangeNotifierProvider<NFCNotifier>(
      create: (_) => NFCNotifier(),
      builder: (context, child) => _IntimeScreenBody(),
    );
  }
}

class _IntimeScreenBody extends StatefulWidget {
  @override
  State<_IntimeScreenBody> createState() => _IntimeScreenBodyState();
}

class _IntimeScreenBodyState extends State<_IntimeScreenBody> {
  String debugMessage = '';
  // Controller and focus nodes
  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode(); // for RawKeyboardListener

  // Track last RFID handled to avoid duplicate dialog launches
  String _lastHandledRfid = '';
  // Buffer built from hardware keyboard events
  String _kbBuffer = '';
  // Threshold to auto-submit (adjust if needed)
  static const int _autoSubmitLength = 10;

  void updateDebugMessage(String msg) {
    if (mounted) {
      setState(() {
        debugMessage = msg;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Start NFC listening (optional) — kept for compatibility with existing flows
      try {
        Provider.of<NFCNotifier>(context, listen: false)
            .startNFCOperation(nfcOperation: NFCOperation.read);
      } catch (_) {}

      // Give focus to the RawKeyboardListener so hardware keyboard events are captured
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
      // Ensure soft keyboard is hidden
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  // Handle hardware key events using the newer KeyEvent API
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // Try to use the character if available (works for HID scanners/keyboards)
      final String? char = event.character;

      if (char != null && char.isNotEmpty) {
        final digits = char.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          _kbBuffer += digits;
          _updateControllerFromBuffer();
        }
      } else {
        // No printable char available — handle special keys
        final key = event.logicalKey;
        if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
          _submitKbBuffer();
        } else if (key == LogicalKeyboardKey.backspace) {
          if (_kbBuffer.isNotEmpty) {
            _kbBuffer = _kbBuffer.substring(0, _kbBuffer.length - 1);
            _updateControllerFromBuffer();
          }
        }
      }

      // Auto-submit when buffer reaches threshold
      if (_kbBuffer.length >= _autoSubmitLength && _lastHandledRfid != _kbBuffer) {
        _submitKbBuffer();
      }
    }
  }

  void _updateControllerFromBuffer() {
    // Update the read-only TextField visually
    _rfidController.text = _kbBuffer;
    _rfidController.selection =
        TextSelection.fromPosition(TextPosition(offset: _rfidController.text.length));
    // Keep focus on the RawKeyboardListener and keep soft keyboard hidden
    if (!_keyboardFocusNode.hasFocus) FocusScope.of(context).requestFocus(_keyboardFocusNode);
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _submitKbBuffer() {
    if (_kbBuffer.isEmpty) return;
    _lastHandledRfid = _kbBuffer;

    // Capture a copy and then clear buffer after showing dialog
    final String submitted = _kbBuffer;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use provider to get vcid if available
      final provider = Provider.of<NFCNotifier>(context, listen: false);
      final currentVcid = provider.vcid?.toString() ?? '';

      showResultDialogi(
        context,
        'Hardware input detected',
        () {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            // Clear buffer and controller, restart NFC if you want, and refocus the keyboard listener
            _kbBuffer = '';
            _lastHandledRfid = '';
            _rfidController.clear();
            try {
              Provider.of<NFCNotifier>(context, listen: false)
                  .startNFCOperation(nfcOperation: NFCOperation.read);
            } catch (_) {}
            FocusScope.of(context).requestFocus(_keyboardFocusNode);
            SystemChannels.textInput.invokeMethod('TextInput.hide');
          });
        },
        currentVcid,
        submitted,
        '1',
      );
    });
  }

  @override
  void dispose() {
    // Do NOT call Provider.dispose() here — provider is managed by ChangeNotifierProvider
    // Just dispose local nodes/controllers
    _keyboardFocusNode.dispose();
    _rfidFocusNode.dispose();
    _rfidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          "In-time",
          style: TextStyle(
            color: Colors.black,
            fontSize: screenWidth * 0.045,
          ),
        ),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
            size: screenWidth * 0.065,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: KeyboardListener(
        focusNode: _keyboardFocusNode,
        autofocus: true,
        onKeyEvent: _handleKeyEvent,
        child: Builder(
          builder: (BuildContext context) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    debugMessage,
                    style: TextStyle(fontSize: screenWidth * 0.035),
                  ),

                  // Display the buffer in a read-only TextField so soft keyboard won't appear
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Opacity(opacity: 0.0,child: TextField(
                      controller: _rfidController,
                      focusNode: _rfidFocusNode,
                      readOnly: true, // prevents soft keyboard from opening
                      showCursor: true,
                      enableInteractiveSelection: false,
                      decoration: InputDecoration(
                        labelText: 'RFID',
                        hintText: 'Waiting for hardware input...',
                        border: OutlineInputBorder(),
                      ),
                    ),)

                  ),

                  Image.asset(
                    'assets/markattendance.png',
                    width: screenWidth * 0.6,
                    height: screenWidth * 0.6,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: screenHeight * 0.025),

                  Consumer<NFCNotifier>(
                    builder: (context, provider, _) {
                      // Still keep NFC provider messages working as before
                      if (provider.isProcessing) {
                        return Text(
                          'Please hold the card near',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.04,
                          ),
                        );
                      }

                      if (provider.message.isNotEmpty && provider.vcid != null) {
                        WidgetsBinding.instance.addPostFrameCallback((_) async {
                          final currentMessage = provider.message;
                          final currentVcid = provider.vcid;
                          final currentRfid = provider.rfid ?? '';
                          provider.clearNfcData();
                          showResultDialogi(
                            context,
                            currentMessage,
                            () {
                              // Restart NFC listening after dialog closes
                              Future.delayed(Duration(milliseconds: 500), () {
                                if (mounted) {
                                  Provider.of<NFCNotifier>(context, listen: false)
                                      .startNFCOperation(
                                          nfcOperation: NFCOperation.read);
                                }
                              });
                            },
                            currentVcid.toString(),
                            currentRfid,
                            '1',
                          );
                        });
                      }

                      return const SizedBox();
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
