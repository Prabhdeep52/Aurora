import 'package:aurora/secrets.dart';
import 'package:aurora/tts_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:path/path.dart';
import 'dart:io';
import 'dart:typed_data';

Future getImageTotext(final imagePath) async {
  final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final RecognizedText recognizedText =
      await textRecognizer.processImage(InputImage.fromFilePath(imagePath));
  String text = recognizedText.text.toString();
  return text;
}

Future chat(File imagePath) async {
  final image = await imagePath.readAsBytes();
  final imageParts = [DataPart('image/jpeg', image)];
  final model = GenerativeModel(model: 'gemini-pro-vision', apiKey: gemini_key);
  final prompt = TextPart(
      "you are a assistant to a blind person , you have to understand the image and explain it to the person in minimum words.");
  final response = await model.generateContent([
    Content.multi([prompt, imageParts[0]]),
  ]);

  print(response);
  return response.text;
}

class TextDetector extends StatefulWidget {
  const TextDetector({super.key});

  @override
  State<TextDetector> createState() => _TextDetectorState();
}

late String s = "";
bool waitingForRes = false;
List chatHistory = [];
final TTSService flutterTts = TTSService();

class _TextDetectorState extends State<TextDetector> {
  void speak() {
    flutterTts.speak(s);
  }

  @override
  void initState() {
    super.initState();
    flutterTts.speak("Click at the center of screen to start. ");
  }

  final ImagePicker picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Center(
            child: GestureDetector(
              onTap: () async {
                final XFile? image =
                    await picker.pickImage(source: ImageSource.camera);

                File file = File(image!.path);
                setState(() {
                  waitingForRes = true;
                });
                String a = await chat(file);

                setState(() {
                  waitingForRes = false;
                  s = a;
                  print(s);
                  speak();
                });
              },
              child: Container(
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(20)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color.fromARGB(255, 114, 206, 146),
                      Color.fromARGB(255, 132, 192, 230)
                    ],
                  ),
                ),
                child: Center(
                    child: Text(
                  waitingForRes ? " waiting for response" : "Click Here",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w500),
                )),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
