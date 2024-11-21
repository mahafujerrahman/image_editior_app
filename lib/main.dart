import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

void main() {
  runApp(ImageEditorApp());
}

class ImageEditorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Editor',
      home: ImageEditorScreen(),
    );
  }
}

class ImageEditorScreen extends StatefulWidget {
  @override
  _ImageEditorScreenState createState() => _ImageEditorScreenState();
}

class _ImageEditorScreenState extends State<ImageEditorScreen> {
  File? _image;
  Color _selectedColor = Colors.black;
  ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _picker = ImagePicker();
  List<Offset?> _points = [];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _saveImage() async {
    final image = await _screenshotController.capture();
    if (image == null) return;

    final directory = await getApplicationDocumentsDirectory();
    final imagePath = '${directory.path}/edited_image.jpg';
    final file = File(imagePath);
    await file.writeAsBytes(image);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Image saved to $imagePath')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Image Editor'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickImage,
            child: Text('Upload Image'),
          ),
          if (_image != null)
            Expanded(
              child: Screenshot(
                controller: _screenshotController,
                child: Stack(
                  children: [
                    Image.file(_image!),
                    GestureDetector(
                      onPanUpdate: (details) {
                        setState(() {
                          RenderBox? renderBox = context.findRenderObject() as RenderBox?;
                          _points.add(renderBox?.globalToLocal(details.globalPosition));
                        });
                      },
                      onPanEnd: (details) => _points.add(null),
                      child: CustomPaint(
                        painter: _DrawingPainter(_points, _selectedColor),
                        size: Size.infinite,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => _pickColor(context),
            child: Text('Change Color'),
          ),
          ElevatedButton(
            onPressed: _saveImage,
            child: Text('Download Image'),
          ),
        ],
      ),
    );
  }

  void _pickColor(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pick a Color'),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: _selectedColor,
              onColorChanged: (color) {
                setState(() {
                  _selectedColor = color;
                });
              },
            ),
          ),
          actions: [
            TextButton(
              child: Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }
}

class _DrawingPainter extends CustomPainter {
  final List<Offset?> points;
  final Color color;

  _DrawingPainter(this.points, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}


