import 'dart:io';
import 'dart:typed_data';

import 'package:camera_app/infrastructure/utils/color_picker.dart';
import 'package:camera_app/infrastructure/utils/drawing_manager.dart';
import 'package:camera_app/infrastructure/utils/utils.dart';
import 'package:camera_app/presentation/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';

class EditImageScreen extends StatefulWidget {
  final String imagePath;
  const EditImageScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<EditImageScreen> createState() => _EditImageScreenState();
}

class _EditImageScreenState extends State<EditImageScreen>
    with WidgetsBindingObserver {
  ScreenshotController screenshotController = ScreenshotController();
  DrawingManager drawingManager = DrawingManager();
  FocusNode focusNode = FocusNode();
  FocusScopeNode focusScopeNode = FocusScopeNode();

  late TextEditingController _txtEditcontroller;
  List<TextOverlay> textsOnImage = [];

  bool _isDrawing = false;
  bool _isTexting = false;
  bool _isTextingTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    focusNode.addListener(() {
      if (!focusNode.hasFocus && !focusScopeNode.hasFocus) {
        setState(() {
          _isTexting = false;
        });
      }
    });
    _txtEditcontroller = TextEditingController();
    _txtEditcontroller.addListener(() {
      setState(() {
        _isTextingTyping = _txtEditcontroller.text.isNotEmpty;
      });
    });
  }

  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    final isKeyboardOpen = bottomInset > 0.0;
    /*  if (!isKeyboardOpen && _isTexting) {
      setState(() {
        _isTexting = false;
      });
    } */
  }

  @override
  void dispose() {
    focusNode.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _txtEditcontroller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // Fila de acciones inicial.
    final initialRow = Row(
      children: [
        CircularIconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        const Spacer(),
        CircularIconButton(
          icon: const Icon(Icons.brush),
          onPressed: () => setState(() => _isDrawing = !_isDrawing),
        ),
        const SizedBox(width: 10),
        CircularIconButton(
          icon: const Icon(Icons.text_fields),
          onPressed: () => setState(() {
            _isTexting = !_isTexting;
            _isTextingTyping = false;
            _txtEditcontroller.clear();
            if (_isTexting) {
              focusNode.requestFocus();
            }
          }),
        ),
      ],
    );

    //Filas de acciones para dibujar
    final drawingRow = Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: TextButton(
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              // Finaliza el modo de dibujo.
              setState(() {
                _isDrawing = false;
              });
            },
          ),
        ),
        const Spacer(),
        CircularIconButton(
          icon: const Icon(Icons.undo),
          onPressed: () {
            drawingManager.undo();
            setState(() {});
          },
        ),
        const SizedBox(width: 10),
        CircularIconButton(
          icon: const Icon(Icons.color_lens),
          onPressed: () {
            // Restablece el color del trazo a blanco.
            setState(() {
              drawingManager.color = Colors.white;
            });
            // Muestra el selector de color.
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  content: SizedBox(
                    height: 200,
                    child: ColorPicker(
                      onColorSelected: (color) {
                        setState(() {
                          drawingManager.color = color;
                        });
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );

    // Fila de acciones para añadir texto
    final textRow = Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withOpacity(0.5),
          ),
          child: TextButton(
            child: const Text(
              'OK',
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              // Finaliza el modo de añadir texto.
              setState(() {
                _isTexting = false;
                textsOnImage.add(
                  TextOverlay(
                    text: _txtEditcontroller.text,
                    position: Offset(size.width / 2.5, size.height / 2),
                  ),
                );
              });
            },
          ),
        ),
        const Spacer(),
      ],
    );

    // Imagen y dibujo
    return FocusScope(
      node: focusScopeNode,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isTexting = false;
          });
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: Colors.black,
          body: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Screenshot(
                    controller: screenshotController,
                    child: Stack(
                      // Imagen y dibujo
                      children: [
                        GestureDetector(
                          onPanStart: (details) {
                            if (_isDrawing) {
                              drawingManager.startStroke(details.localPosition);
                              setState(() {});
                            }
                          },
                          onPanUpdate: (details) {
                            if (_isDrawing) {
                              drawingManager
                                  .continueStroke(details.localPosition);
                              setState(() {});
                            }
                          },
                          onPanEnd: (details) {
                            if (_isDrawing) {
                              drawingManager.endStroke();
                              setState(() {});
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.only(top: size.width * 0.1),
                            child: Image.file(
                              File(widget.imagePath),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        // Dibujos
                        CustomPaint(
                          painter: DrawingPainter(
                            strokes: drawingManager.strokes,
                            color: drawingManager.color,
                          ),
                        ),
                        // Textos en la imagen
                        ...textsOnImage.map((textOverlay) {
                          return Positioned(
                            left: textOverlay.position.dx,
                            top: textOverlay.position.dy,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                setState(() {
                                  // Selecciona el indice del texto en la lista.
                                  int index = textsOnImage.indexOf(textOverlay);
                                  if (index != -1) {
                                    double scaleFactor = 7.0;
                                    textsOnImage[index] = TextOverlay(
                                      position: textOverlay.position +
                                          details.delta * scaleFactor,
                                      text: textOverlay.text,
                                    );
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  textOverlay.text,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 20,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                //Cuadro de texto y botón de enviar
                _isDrawing || _isTexting
                    ? Container()
                    : Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.only(bottom: 15),
                          width: size.width * 0.95,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: size.width * 0.75,
                                padding: const EdgeInsets.all(20),
                                child: const CustomTextFormField(
                                  maxLines: 1,
                                  style: TextStyle(color: Colors.white),
                                  hint: 'Añade un comentario...',
                                  labelField: "Añade un comentario...",
                                ),
                              ),
                              Container(
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.lightGreen,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.send),
                                  color: Colors.white,
                                  onPressed: () {
                                    screenshotController
                                        .capture(
                                            delay: const Duration(
                                                milliseconds: 10))
                                        .then((capturedImage) {
                                      showCapturedWidget(
                                          context, capturedImage!);
                                    }).catchError((onError) {
                                      print(onError);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                // Fondo oscuro
                _isTexting
                    ? Container(
                        height: size.height,
                        width: size.width,
                        color: Colors.black.withOpacity(0.65),
                      )
                    : Container(),
                // Textfield en pantalla
                _isTexting
                    ? Align(
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _isTextingTyping
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: LayoutBuilder(
                            builder: (BuildContext context,
                                BoxConstraints constraints) {
                              final text = TextPainter(
                                text: TextSpan(
                                    text: _txtEditcontroller.text.isEmpty
                                        ? 'Añade texto.'
                                        : _txtEditcontroller.text,
                                    style: const TextStyle(fontSize: 25)),
                                maxLines: 1,
                                textDirection: TextDirection.ltr,
                              )..layout(
                                  minWidth: constraints.minWidth,
                                  maxWidth: constraints.maxWidth,
                                );

                              return SizedBox(
                                width: text.size.width + 30,
                                child: TextFormField(
                                  controller: _txtEditcontroller,
                                  focusNode: focusNode,
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  style: TextStyle(
                                    color: _isTextingTyping
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  decoration: const InputDecoration(
                                    fillColor: Colors.transparent,
                                    filled: true,
                                    hintText: 'Añade texto.',
                                    hintStyle: TextStyle(
                                      color: Color.fromARGB(255, 129, 129, 129),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 25,
                                    ),
                                    border: InputBorder.none,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      )
                    : Container(),
                // Fila de acciones
                Positioned(
                  top: size.height * 0.08,
                  left: 5,
                  right: 5,
                  child: SizedBox(
                    width: size.width,
                    child: _isTexting
                        ? textRow
                        : (_isDrawing ? drawingRow : initialRow),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> showCapturedWidget(
      BuildContext context, Uint8List capturedImage) {
    return showDialog(
      useSafeArea: false,
      context: context,
      builder: (context) => Scaffold(
        body: Center(child: Image.memory(capturedImage)),
      ),
    );
  }
}
