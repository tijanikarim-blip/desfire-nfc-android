import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:convert/convert.dart';
import 'dart:typed_data';

void main() {
  runApp(const DesFireApp());
}

class DesFireApp extends StatelessWidget {
  const DesFireApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DESFire Key Gen',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF3B82F6),
        scaffoldBackgroundColor: const Color(0xFF0B0F19),
        cardTheme: CardThemeData(
          color: const Color(0xFF111827),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B0F19),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF374151)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
          ),
          labelStyle: const TextStyle(color: Color(0xFF9CA3AF)),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _masterKeyController =
      TextEditingController(text: "00000000000000001111111111111111");
  final TextEditingController _ridController =
      TextEditingController(text: "000000000000");
  final TextEditingController _uidController =
      TextEditingController(text: "A1B2C3D4E5F6");

  String _result = "";
  bool _showResult = false;

  void _generateKey() {
    try {
      final String masterKeyHex = _masterKeyController.text.replaceAll(" ", "");
      final String ridHex = _ridController.text.replaceAll(" ", "");
      final String uidHex = _uidController.text.replaceAll(" ", "");

      // Step 1: Combine RID and UID and pad to 8-byte boundary
      String combinedHex = ridHex + uidHex;
      int bytesLen = combinedHex.length ~/ 2;
      int padLen = (8 - (bytesLen % 8)) % 8;
      combinedHex += "00" * padLen;

      final Uint8List block = Uint8List.fromList(hex.decode(combinedHex));
      final Uint8List keyBytes = Uint8List.fromList(hex.decode(masterKeyHex));

      // 3DES handling: if 16 bytes, expand to 24 bytes (K1, K2, K1)
      Uint8List fullKeyBytes = keyBytes;
      if (keyBytes.length == 16) {
        fullKeyBytes = Uint8List(24);
        fullKeyBytes.setRange(0, 16, keyBytes);
        fullKeyBytes.setRange(16, 24, keyBytes.sublist(0, 8));
      }

      final key = encrypt.Key(fullKeyBytes);
      // In encrypt package, TripleDES is the engine, and we use AESMode.ecb for the mode wrapper
      final encrypter = encrypt.Encrypter(encrypt.TripleDES(key: key, mode: encrypt.AESMode.ecb));
      
      // TripleDES ECB doesn't use an IV, but the API requires it (or use empty)
      final encrypted = encrypter.encryptBytes(block, iv: encrypt.IV.fromLength(8));
      
      String res = hex.encode(encrypted.bytes).toUpperCase();
      if (res.length > 32) res = res.substring(0, 32);

      setState(() {
        _result = res;
        _showResult = true;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("DESFire EV1 Generator", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFF3B82F6).withOpacity(0.1), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: const Text(
                "Regenerate session keys from master key data.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF9CA3AF)),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _masterKeyController,
                      decoration: const InputDecoration(labelText: "Master Key (Hex)"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _ridController,
                      decoration: const InputDecoration(labelText: "RID (Hex)"),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _uidController,
                      decoration: const InputDecoration(labelText: "Card UID (Hex)"),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _generateKey,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("GENERATE SESSION KEY", 
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                    ),
                    if (_showResult) ...[
                      const SizedBox(height: 24),
                      const Text("GENERATED SESSION KEY", 
                        style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                _result,
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 16, color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy, color: Color(0xFF9CA3AF)),
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: _result));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Copied to clipboard")),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
