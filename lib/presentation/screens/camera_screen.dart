import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens.dart';

class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraScreen({super.key, required this.cameras});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _initilizeCamera();
  }

  void _initilizeCamera() {
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.high,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
      if (e is CameraException) {
        switch (e.code) {
          case 'CameraAccessDenied':
            // Handle access errors here.
            break;
          default:
            // Handle other errors here.
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    if (!_controller.value.isInitialized) {
      return Container();
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Vista previa de la cámara
          Container(
            margin: EdgeInsets.only(top: size.height * 0.1),
            child: CameraPreview(_controller),
          ),
          // Botones de cerrar y flash
          Positioned(
            top: size.height * 0.1,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de cerrar
                  GestureDetector(
                    onTap: () {
                      //Navigator.of(context).pop();
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                  // Botón de flash
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.flash_on,
                      color: Colors.white,
                      size: 25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Botones de captura, cambio de cámara y galería
          Positioned(
            bottom: 18.0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Botón de galería
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Icon(
                        Icons.photo,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                  // Botón de captura
                  Stack(
                    children: [
                      //Borde circular
                      Container(
                        width: 65,
                        height: 65,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                      ),
                      // Circulo central
                      Positioned.fill(
                        child: GestureDetector(
                          onTap: () async {
                            // Asegura de esperar a que la cámara esté lista antes de tomar una foto.
                            await _initializeControllerFuture;

                            // Configura el modo de flash como "apagado" para evitar que se active automáticamente.
                            await _controller.setFlashMode(FlashMode.off);

                            final XFile file = await _controller.takePicture();

                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditImageScreen(imagePath: file.path),
                                ),
                              );
                            }
                            // Obtén el tamaño del archivo en MB
                            /* final fileSizeInBytes =
                                File(file.path).lengthSync();
                            final fileSizeInMB =
                                fileSizeInBytes / (1024 * 1024);
                            print('Tamaño del archivo: $fileSizeInMB MB'); */
                          },
                          child: Container(
                            margin: const EdgeInsets.all(11.5),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Botón de cambio de cámara
                  GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.5),
                      ),
                      child: const Icon(
                        Icons.cached,
                        color: Colors.white,
                        size: 25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          /* Positioned(
            bottom: 18.0,
            left: 0,
            right: 0,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Stack(
                children: [
                  //Borde circular
                  Container(
                    width: 65,
                    height: 65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                    ),
                  ),
                  // Circulo central
                  Positioned.fill(
                    child: GestureDetector(
                      onTap: () {},
                      child: Container(
                        margin: const EdgeInsets.all(11.5),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ), */
        ],
      ),
    );
  }
}
