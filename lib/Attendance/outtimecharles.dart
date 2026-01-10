import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:provider/provider.dart';

import 'dailogei.dart';
import 'nfcnotifier.dart';
import '../ApiCalls/apicall.dart';

class Outtimecharles extends StatelessWidget {
  const Outtimecharles({super.key});

  @override
  Widget build(BuildContext context) {
    // Set attendance status for Out Time
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
  // Controller and focus node for the RFID text box
  final TextEditingController _rfidController = TextEditingController();
  final FocusNode _rfidFocusNode = FocusNode();
  final FocusNode _keyboardFocusNode = FocusNode(); // for capturing hardware keys
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
      // Start NFC listening (keep compatibility with existing provider flow)
      try {
        Provider.of<NFCNotifier>(context, listen: false)
            .startNFCOperation(nfcOperation: NFCOperation.read);
      } catch (_) {}

      // Give focus to the hardware keyboard listener and hide soft keyboard
      FocusScope.of(context).requestFocus(_keyboardFocusNode);
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });
  }

  // Handle hardware key events using KeyEvent API
  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final String? char = event.character;
      if (char != null && char.isNotEmpty) {
        final digits = char.replaceAll(RegExp(r'[^0-9]'), '');
        if (digits.isNotEmpty) {
          _kbBuffer += digits;
          _updateControllerFromBuffer();
        }
      } else {
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

      if (_kbBuffer.length >= _autoSubmitLength && _lastHandledRfid != _kbBuffer) {
        _submitKbBuffer();
      }
    }
  }

  void _updateControllerFromBuffer() {
    _rfidController.text = _kbBuffer;
    _rfidController.selection =
        TextSelection.fromPosition(TextPosition(offset: _rfidController.text.length));
    if (!_keyboardFocusNode.hasFocus) FocusScope.of(context).requestFocus(_keyboardFocusNode);
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _submitKbBuffer() {
    if (_kbBuffer.isEmpty) return;
    _lastHandledRfid = _kbBuffer;
    final String submitted = _kbBuffer;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<NFCNotifier>(context, listen: false);
      final currentVcid = provider.vcid;

      showResultDialogi(
        context,
        'Hardware input detected',
        () {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
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
        currentVcid.toString(),
        submitted,
        '2',
      );
      
      // Call the out-time lookup API
      
    });
  }

  @override
  void dispose() {
    // Don't call provider.dispose(); provider is managed by ChangeNotifierProvider
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
          "Out-time",
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
                  // Numeric-only, hidden (opacity 0) RFID text box remains for compatibility
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
                    child: Opacity(
                      opacity: 0.0,
                      child: TextField(
                        controller: _rfidController,
                        focusNode: _rfidFocusNode,
                        autofocus: true,
                        readOnly: true,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: InputDecoration(
                          labelText: 'RFID',
                          hintText: 'Enter numeric RFID',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
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
                      // Provider-originated RFID should still fill the field when available
                      final rawRfid = provider.rfid;
                      if (rawRfid != null && rawRfid.isNotEmpty) {
                        final sanitizedRfid = rawRfid.replaceAll(RegExp(r'[^0-9]'), '');
                        if (_rfidController.text != sanitizedRfid) {
                          _rfidController.text = sanitizedRfid;
                          _rfidController.selection =
                              TextSelection.fromPosition(TextPosition(offset: _rfidController.text.length));
                          FocusScope.of(context).requestFocus(_rfidFocusNode);
                        }
                      }

                      // Manual/hardware capture: if controller reaches threshold and wasn't handled yet
                      final manualRfid = _rfidController.text.replaceAll(RegExp(r'[^0-9]'), '');
                      if (manualRfid.length >= _autoSubmitLength && _lastHandledRfid != manualRfid) {
                        _lastHandledRfid = manualRfid;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          final dialogMessage = debugMessage.isNotEmpty ? debugMessage : 'Manual RFID entry detected';
                          final currentVcid = provider.vcid;
                          showResultDialogi(
                            context,
                            dialogMessage,
                            () {
                              Future.delayed(const Duration(milliseconds: 300), () {
                                if (mounted) {
                                  _rfidController.clear();
                                  _lastHandledRfid = '';
                                  Provider.of<NFCNotifier>(context, listen: false)
                                      .startNFCOperation(nfcOperation: NFCOperation.read);
                                  FocusScope.of(context).requestFocus(_rfidFocusNode);
                                }
                              });
                            },
                            currentVcid.toString(),
                            _rfidController.text,
                            '2', // Out-time status
                          );
                          
                          // Call the out-time lookup API
                          
                        });
                      }

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
                                      .startNFCOperation(nfcOperation: NFCOperation.read);
                                }
                              });
                            },
                            currentVcid.toString(),
                            currentRfid,
                            '2', // Out-time status
                          );
                          
                          // Call the out-time lookup API
                         
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

