import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/widgets.dart' show BuildContext, CustomPainter;
import 'package:flutter/material.dart';

class SvgPainter extends HookWidget {
  final BuildContext context;
  final double? height;
  final double? width;
  final String? svgString;
  final String? svgUri;
  final Color? selectedColor;
  final EdgeInsetsGeometry? padding;
  final void Function(String, DrawableShape)? onTap;
  late double targetWidth;
  late double targetHeight;
  final ValueNotifier<String>? selectedIndex;
  final List<String>? activeSvgId;

  SvgPainter(this.context,
      {this.width,
      this.height,
      this.svgString,
      this.svgUri,
      this.onTap,
      this.padding,
      this.selectedColor = Colors.red,
      this.selectedIndex,
      this.activeSvgId})
      : targetWidth = width ??
            MediaQuery.of(context).size.width -
                ((padding?.horizontal ?? 0) * 2),
        targetHeight = (height ?? 200) - ((padding?.vertical ?? 0) * 2);

  @override
  Widget build(BuildContext context) {
    final ValueNotifier<DrawableRoot?> root = useState<DrawableRoot?>(null);
    final ValueNotifier<List<MyCustomPainter>> painters =
        useState<List<MyCustomPainter>>([]);

    final ValueNotifier<bool> isError = useState<bool>(false);
    final ValueNotifier<double> scale = useState<double>(1);
    final isMounted = useIsMounted();

    Future<void> _fetchSvg(String svgUri) async {
      try {
        final Uint8List bytes =
            await httpGet(svgUri, headers: <String, String>{});
        if (!isMounted()) {
          return;
        }

        final DrawableRoot svgRoot = await svg.fromSvgBytes(bytes, '');
        root.value = svgRoot;
      } catch (_) {
        isError.value = true;
      }
    }

    Future<void> _parseSvg() async {
      try {
        root.value = await svg.fromSvgString(svgString!, '');
      } catch (_) {
        isError.value = true;
      }
    }

    useEffect(() {
      if (svgUri != null && svgUri!.isNotEmpty) {
        _fetchSvg(svgUri!);
      } else if (svgString != null && svgString!.isNotEmpty) {
        _parseSvg();
      }
    }, []);

    useEffect(() {
      Size getBound(Drawable s, Size bound) {
        if (s is DrawableShape) {
          final double boundX = max(bound.width, s.path.getBounds().right);
          final double boundY = max(bound.height, s.path.getBounds().bottom);
          bound = Size(boundX, boundY);
        } else if (s is DrawableGroup) {
          s.children!.forEach((Drawable e) {
            bound = getBound(e, bound);
          });
        }
        return bound;
      }

      void addShape(Drawable s, String gid) {
        if (s is DrawableShape) {
          ui.Color color = s.style.fill?.color ?? Colors.black;
          if (activeSvgId != null) {
            if (!activeSvgId!.contains(gid)) {
              color = s.id != null && s.id!.startsWith('side')
                  ? const Color(0xffa3a3a3)
                  : const Color(0xffb2b2b2);
            }
          }
          painters.value.add(
            MyCustomPainter(gid, s, scale.value, color),
          );
        } else if (s is DrawableGroup) {
          //count += s.children!.length;
          s.children!.forEach((Drawable e) {
            addShape(e, gid);
          });
        }
      }

      if (root.value == null) {
        return;
      }

      var bound = Size(targetWidth, targetHeight);
      root.value?.children.forEach((Drawable e) {
        if (e is DrawableGroup && e.children != null) {
          e.children!.forEach((Drawable s) {
            bound = getBound(s, bound);
          });
        }
      });

      final double scaleX = targetWidth / bound.width;
      final double scaleY = targetHeight / bound.height;

      scale.value = min(scaleX, scaleY);

      painters.value.clear();
      int count = -1;
      root.value!.children.forEach((Drawable e) {
        if (e is DrawableGroup && e.children != null) {
          count += e.children!.length;
          e.children!.forEach((Drawable s) {
            addShape(s, e.id ?? '');
          });
        }
      });
    }, [root.value]);

    if (isError.value) {
      return const SizedBox();
    }

    if (root.value == null) {
      return Container(
          width: width,
          height: height,
          child: const Center(
            child: CircularProgressIndicator(),
          ));
    }

    final MyCustomPainter? currentSelected =
        selectedIndex != null && selectedIndex!.value != ''
            ? painters.value
                .where((e) =>
                    e.groupId == selectedIndex!.value &&
                    e.drawable.id != null &&
                    e.drawable.id!.startsWith('top'))
                .first
            : null;

    final MyCustomPainter? selectedRegion =
        selectedIndex != null && selectedIndex!.value != ''
            ? MyCustomPainter(
                currentSelected!.groupId,
                currentSelected.drawable,
                scale.value,
                selectedColor!,
                isSelected: true,
              )
            : null;

    return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: onTap == null
            ? null
            : (TapDownDetails details) {
                bool isHit = false;
                for (int i = 0; i < painters.value.length; i++) {
                  if (painters.value[i].hitTest(details.localPosition) &&
                      //painters.value[i].index > 0 &&
                      painters.value[i].groupId != 'GRAPHIC') {
                    if (activeSvgId != null) {
                      if (!activeSvgId!.contains(painters.value[i].groupId)) {
                        break;
                      }
                    }
                    isHit = true;

                    if (selectedIndex?.value != painters.value[i].groupId) {
                      selectedIndex?.value = painters.value[i].groupId ?? '';
                    } else {
                      selectedIndex?.value = '';
                    }
                    onTap?.call(painters.value[i].groupId ?? '',
                        painters.value[i].drawable);
                    break;
                  }
                }
                if (!isHit) {
                  selectedIndex?.value = '';
                }
              },
        child: Container(
            //padding: padding,
            child: Stack(children: [
          ...painters.value
              .map((MyCustomPainter p) => CustomPaint(
                    painter: p,
                    size: Size(targetWidth, targetHeight),
                  ))
              .toList(),
          if (selectedIndex != null && selectedIndex!.value != '')
            CustomPaint(
              painter: selectedRegion,
              size: Size(targetWidth, targetHeight),
            ),
        ])));
  }
}

class MyCustomPainter extends CustomPainter {
  final String? groupId;
  final DrawableShape drawable;
  final double scale;
  final Color color;
  final Paint myPaint = Paint();
  final bool isSelected;

  MyCustomPainter(this.groupId, this.drawable, this.scale, this.color,
      {this.isSelected = false});

  late Path path;

  @override
  void paint(Canvas canvas, Size size) {
    final Matrix4 matrix4 = Matrix4.identity();
    matrix4.scale(scale, scale);
    path = drawable.path.transform(matrix4.storage);

    myPaint.color = color;
    if (isSelected) {
      myPaint.style = PaintingStyle.stroke;
      myPaint.strokeWidth = 2;
    }
    canvas.drawPath(path, myPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool hitTest(Offset position) {
    return path.contains(position);
  }
}

Future<Uint8List> httpGet(String url, {Map<String, String>? headers}) async {
  final HttpClient httpClient = HttpClient();
  final Uri uri = Uri.base.resolve(url);
  final HttpClientRequest request = await httpClient.getUrl(uri);
  if (headers != null) {
    headers.forEach((String key, String value) {
      request.headers.add(key, value);
    });
  }
  final HttpClientResponse response = await request.close();

  if (response.statusCode != HttpStatus.ok) {
    throw HttpException('Could not get network asset', uri: uri);
  }
  return consolidateHttpClientResponseBytes(response);
}
