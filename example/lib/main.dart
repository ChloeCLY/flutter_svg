import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show BuildContext, CustomPainter;
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/svg_painter.dart';

void main() {
  runApp(_MyApp());
}

class _MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _MyHomePage(),
    );
  }
}

class _MyHomePage extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState<String>('');

    return Scaffold(
      appBar: AppBar(
        title: const Text('test'),
      ),
      body: Container(
          alignment: Alignment.center,
          height: 400,
          child: SvgPainter(context,
              height: 400,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
              selectedIndex: selectedIndex,
              svgUri:
                  //'https://totalticketing-ets-mgm-prod2-singapore-web-files.s3.amazonaws.com/media/seatingtemplate/svg_three_d_drawing/34/mgm_gala_jan_0331_627pm_3d_final_rename100.svg',
                  //'https://sunod.qwerasdf.gq/gpi/v1/media/seatingtemplate/svg_three_d_drawing/36/3d_svg_34KV2A1.svg',
                  //'https://totalticketing-ets-sun-staging-singapore-web-files.s3.amazonaws.com/media/seatingtemplate/svg_three_d_drawing/42/McPherson0910_v8_3D.svg',
                  'https://sunod-lab.oss-cn-hongkong.aliyuncs.com/seatmap/613a04fc-5b94-44bf-823c-edc415a6ca38.svg',
              //activeSvgId: ['SECTION-PURPLE'],
              onTap: (String groupId, DrawableShape shape) {
            print(groupId);
            print(shape.id);
          })),
    );
  }
}
