import 'dart:io';

import 'package:ai_face_generator/blocs/fake_face/fake_face_bloc.dart';
import 'package:ai_face_generator/models/fake_face_model.dart';
import 'package:ai_face_generator/models/theme_provider.dart';
import 'package:download/download.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  bool _loading = true;
  bool _darkMode = false;
  final FakeFaceBloc _fakeFaceBloc = FakeFaceBloc();
  FakeFace _fakeFace = FakeFace();
  late Uint8List _image;

  late DarkThemeProvider themeChange;

  Future _downloadImage() async {
    if (_loading) return;
    Directory? appDir;
    final stream = Stream.fromIterable(_image);
    if (kIsWeb) {
      await download(stream, _fakeFace.fileName!);
      return;
    } else if (Platform.isAndroid) {
      appDir = Directory('/storage/emulated/0/Download');
    } else if (Platform.isIOS) {
      appDir = await getApplicationDocumentsDirectory();
    } else {
      appDir = await getDownloadsDirectory();
    }
    String pathName = appDir?.path ?? "";
    String destinationPath = "$pathName${Platform.isWindows ? "\\" : "/"}${_fakeFace.fileName}";
    await download(stream, destinationPath);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'The image has been downloaded successfully to $destinationPath',
        ),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  final Uri _gitUrl = Uri.parse('https://github.com/srinivasa-dev/ai-face-generator');
  final Uri _androidUrl = Uri.parse('https://github.com/srinivasa-dev/ai-face-generator/releases/download/1.2/ai_face_generator.apk');
  final Uri _webUrl = Uri.parse('https://srinivasa-dev.github.io/ai-face-generator/');
  final Uri _windowsUrl = Uri.parse('https://github.com/srinivasa-dev/ai-face-generator/releases/download/1.2/ai-face-generator.exe');

  Future<void> _launchUrl(url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        themeChange = Provider.of<DarkThemeProvider>(context, listen: false);
        _darkMode = themeChange.darkTheme;
      });
    });
    _fakeFaceBloc.add(LoadFakeFace(context: context));
    super.initState();
  }

  @override
  void dispose() {
    _fakeFaceBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Face Generator'),
        actions: [
          IconButton(
            onPressed: () {
              settingsDialog();
            },
            splashRadius: 10.0,
            icon: const Icon(
              Icons.settings_rounded,
            ),
          ),
        ],
      ),
      body: BlocConsumer<FakeFaceBloc, FakeFaceState>(
        bloc: _fakeFaceBloc,
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth > constraints.maxHeight) {
                  return Row(
                    children: [
                      Expanded(child: imageBuild(state)),
                      const SizedBox(width: 20.0,),
                      Expanded(
                        child: buttonWidget(),
                      ),
                    ],
                  );
                } else {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      imageBuild(state),
                      buttonWidget(),
                    ],
                  );
                }
              },
            ),
          );
        },
        listener: (context, state) {
          if(state is FakeFaceLoadingState) {
            setState(() {
              _loading = true;
            });
          } else if (state is FakeFaceLoadedState) {
            setState(() {
              _fakeFace = state.fakeFace;
              _image = state.uIntImage;
              _loading = false;
            });
          } else if (state is FakeFaceErrorState) {
            setState(() {
              _loading = false;
            });
          } else {
            setState(() {
              _loading = false;
            });
          }
        },
      ),
    );
  }

  settingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10.0)),
          ),
          // contentPadding: EdgeInsets.only(top: 10.0),
          content: StatefulBuilder(
              builder: (context, onRefresh) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkWell(
                      onTap: () {
                        onRefresh(() {
                          setState(() {
                            _darkMode = !_darkMode;
                          });
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 5.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Icon(
                              _darkMode ? Icons.dark_mode : Icons.light_mode,
                            ),
                            Switch(
                              value: _darkMode,
                              onChanged: (value) {
                                onRefresh(() {
                                  setState(() {
                                    _darkMode = value;
                                    themeChange.darkTheme = value;
                                  });
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10.0,),
                    RichText(
                      text: TextSpan(
                        text: 'This app is built on ',
                        style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0),
                        children: [
                          TextSpan(
                            text: 'Flutter ',
                            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.primary),
                          ),
                          TextSpan(
                            text: 'by Yash Kalekar ',
                            style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
              ),
              child: Text(
                'CLOSE',
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.none),
              ),
            ),
          ],
        );
      },
    );
  }

  TextSpan linkText({
    required String text,
    required Uri url,
  }) {
    return TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.copyWith(fontSize: 16.0, color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.none),
      recognizer: TapGestureRecognizer()..onTap = () {
        _launchUrl(url);
      },
      children: [
        WidgetSpan(
          child: Icon(
            Icons.open_in_new,
            color: Theme.of(context).colorScheme.primary,
            size: 18.0,
          ),
        ),
      ],
    );
  }

  Widget imageBuild(FakeFaceState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        color: Theme.of(context).hoverColor,
        child: _loading
            ? LottieBuilder.asset(
          'assets/lottie_animations/face_load.json',
        ) : state is FakeFaceLoadedState ? Image.memory(
          _image,
          fit: BoxFit.contain,
        ) : Container(),
      ),
    );
  }

  Widget buttonWidget() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: _loading ? null : () {
              _fakeFaceBloc.add(LoadFakeFace(context: context));
            },
            child: const Text(
              'GENERATE',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20.0,),
        ElevatedButton(
          onPressed: _loading ? null : () {
            _downloadImage();
          },
          child: const Icon(
            Icons.download,
          ),
        ),
      ],
    );
  }

}
