import 'package:flutter/material.dart';

enum _Tool { pen, highlighter, eraser }

class _Stroke {
  _Stroke(this.points, this.color, this.width, this.erase);
  final List<Offset> points;
  final Color color;
  final double width;
  final bool erase;
}

/// Drawings are kept per question for the lifetime of the app session.
class ScratchpadStore {
  static final Map<String, List<_Stroke>> _byQuestion = {};
}

/// Opens a full-height scratchpad for working a problem by hand.
Future<void> showScratchpad(BuildContext context, String questionId) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: Scratchpad(questionId: questionId)),
  );
}

class Scratchpad extends StatefulWidget {
  const Scratchpad({super.key, required this.questionId});
  final String questionId;

  @override
  State<Scratchpad> createState() => _ScratchpadState();
}

class _ScratchpadState extends State<Scratchpad> {
  late final List<_Stroke> _strokes =
      ScratchpadStore._byQuestion.putIfAbsent(widget.questionId, () => []);
  final List<_Stroke> _redo = [];
  _Stroke? _current;
  _Tool _tool = _Tool.pen;
  int _colorIndex = 0;
  bool _grid = true;

  static const _inks = [Color(0xFF1D2433), Color(0xFF2F6FED), Color(0xFFD9382C), Color(0xFF1F9D55)];

  void _start(Offset p) {
    final stroke = switch (_tool) {
      _Tool.pen => _Stroke([p], _inks[_colorIndex], 2.6, false),
      _Tool.highlighter =>
        _Stroke([p], const Color(0xFFFFD60A).withValues(alpha: 0.4), 16, false),
      _Tool.eraser => _Stroke([p], Colors.white, 22, true),
    };
    setState(() {
      _current = stroke;
      _redo.clear();
    });
  }

  void _move(Offset p) => setState(() => _current?.points.add(p));

  void _end() {
    final c = _current;
    if (c == null) return;
    setState(() {
      if (c.erase) {
        // Erasing removes whole strokes the eraser path touches.
        _strokes.removeWhere((s) => s.points.any((sp) => c.points.any((ep) => (sp - ep).distance < 14)));
      } else {
        _strokes.add(c);
      }
      _current = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SegmentedButton<_Tool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: _Tool.pen, icon: Icon(Icons.edit), tooltip: 'Pen'),
                ButtonSegment(value: _Tool.highlighter, icon: Icon(Icons.highlight), tooltip: 'Highlighter'),
                ButtonSegment(value: _Tool.eraser, icon: Icon(Icons.cleaning_services), tooltip: 'Eraser'),
              ],
              selected: {_tool},
              onSelectionChanged: (s) => setState(() => _tool = s.first),
            ),
            for (var i = 0; i < _inks.length; i++)
              Semantics(
                label: 'Ink color ${i + 1}',
                button: true,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _colorIndex = i;
                    _tool = _Tool.pen;
                  }),
                  child: Container(
                    width: 28,
                    height: 28,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: _inks[i],
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: _colorIndex == i && _tool == _Tool.pen ? cs.primary : Colors.transparent,
                          width: 3),
                    ),
                  ),
                ),
              ),
            IconButton(
              tooltip: 'Undo',
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(() => _redo.add(_strokes.removeLast())),
              icon: const Icon(Icons.undo),
            ),
            IconButton(
              tooltip: 'Redo',
              onPressed: _redo.isEmpty ? null : () => setState(() => _strokes.add(_redo.removeLast())),
              icon: const Icon(Icons.redo),
            ),
            IconButton(
              tooltip: _grid ? 'Hide grid' : 'Show grid',
              onPressed: () => setState(() => _grid = !_grid),
              icon: Icon(_grid ? Icons.grid_on : Icons.grid_off),
            ),
            IconButton(
              tooltip: 'Clear all',
              onPressed: _strokes.isEmpty
                  ? null
                  : () => setState(() {
                        _strokes.clear();
                        _redo.clear();
                      }),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: GestureDetector(
              onPanStart: (d) => _start(d.localPosition),
              onPanUpdate: (d) => _move(d.localPosition),
              onPanEnd: (_) => _end(),
              onPanCancel: _end,
              child: CustomPaint(
                painter: _PadPainter(_strokes, _current, _grid),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _PadPainter extends CustomPainter {
  _PadPainter(this.strokes, this.current, this.grid);
  final List<_Stroke> strokes;
  final _Stroke? current;
  final bool grid;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white);
    if (grid) {
      final p = Paint()
        ..color = const Color(0xFFD7E3F5)
        ..strokeWidth = 1;
      for (double x = 0; x < size.width; x += 24) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      }
      for (double y = 0; y < size.height; y += 24) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      }
    }
    for (final s in strokes) {
      _draw(canvas, s);
    }
    final c = current;
    if (c != null && !c.erase) _draw(canvas, c);
  }

  void _draw(Canvas canvas, _Stroke s) {
    final paint = Paint()
      ..color = s.color
      ..strokeWidth = s.width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;
    if (s.points.length == 1) {
      canvas.drawCircle(s.points.first, s.width / 2, paint..style = PaintingStyle.fill);
      return;
    }
    final path = Path()..moveTo(s.points.first.dx, s.points.first.dy);
    for (var i = 1; i < s.points.length; i++) {
      final mid = (s.points[i - 1] + s.points[i]) / 2;
      path.quadraticBezierTo(s.points[i - 1].dx, s.points[i - 1].dy, mid.dx, mid.dy);
    }
    path.lineTo(s.points.last.dx, s.points.last.dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PadPainter old) => true;
}
