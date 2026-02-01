import 'package:flutter/material.dart';
import 'package:lumi/features/body/presentation/controllers/live2d_controller.dart';

/// Live2D 视图组件
class Live2DView extends StatefulWidget {
  final Live2DController controller;
  final void Function(String hitArea)? onHitAreaTapped;
  final bool enableLookAtTracking;

  const Live2DView({
    super.key,
    required this.controller,
    this.onHitAreaTapped,
    this.enableLookAtTracking = true,
  });

  @override
  State<Live2DView> createState() => _Live2DViewState();
}

class _Live2DViewState extends State<Live2DView> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    if (!controller.isInitialized || controller.textureId == null) {
      return const Live2DPlaceholder();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return GestureDetector(
          onTapDown: (details) => _onTap(details, constraints),
          onPanUpdate: widget.enableLookAtTracking ? _onPanUpdate : null,
          child: Texture(
            textureId: controller.textureId!,
            filterQuality: FilterQuality.medium,
          ),
        );
      },
    );
  }

  void _onTap(TapDownDetails details, BoxConstraints constraints) async {
    final x = details.localPosition.dx / constraints.maxWidth;
    final y = details.localPosition.dy / constraints.maxHeight;

    debugPrint('Tap at ($x, $y)');
    final hitArea = await widget.controller.hitTest(x, y);
    debugPrint('HitTest result: $hitArea');

    if (hitArea != null &&
        hitArea.isNotEmpty &&
        widget.onHitAreaTapped != null) {
      widget.onHitAreaTapped!(hitArea);
    }
  }

  // 没传 details（约束）
  void _onPanUpdate(DragUpdateDetails details) {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    final center = Offset(size.width / 2, size.height / 2);

    final dx = (details.localPosition.dx - center.dx) / (size.width / 2);
    final dy = -(details.localPosition.dy - center.dy) / (size.height / 2);

    widget.controller.setLookAt(dx.clamp(-1.0, 1.0), dy.clamp(-1.0, 1.0));
  }
}

/// Live2D 占位组件
class Live2DPlaceholder extends StatelessWidget {
  const Live2DPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_outline, size: 80, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'Live2D Model',
            style: TextStyle(color: Colors.white38, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            '等待模型加载...',
            style: TextStyle(color: Colors.white24, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
