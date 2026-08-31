import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/models.dart';
import '../data/today.dart';
import '../state/habit_scope.dart';
import '../strings.dart';
import '../theme.dart';

class TaskCalendar extends StatefulWidget {
  const TaskCalendar({super.key});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  late DateTime _month;
  String? _selected;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime get _today => dateFromStamp(todayStamp());

  DateTime _activation(String? stamp) {
    if (stamp == null) return _today;
    return dateFromStamp(stamp);
  }

  DateTime _monthOf(DateTime date) => DateTime(date.year, date.month);

  void _shift(int delta, DateTime first, DateTime last) {
    final next = DateTime(_month.year, _month.month + delta);
    if (next.isBefore(first) || next.isAfter(last)) return;
    setState(() {
      _month = next;
      _selected = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = HabitScope.of(context);
    final today = _today;
    final first = _monthOf(_activation(store.history.activatedOn));
    final last = _monthOf(today);
    final canPrev = _month.isAfter(first);
    final canNext = _month.isBefore(last);
    final selected = _selected == null ? null : store.progressFor(_selected!);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.blush, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: S.previousMonth,
                    onPressed: canPrev ? () => _shift(-1, first, last) : null,
                    icon: const Icon(Icons.chevron_left_rounded),
                    color: AppColors.pinkDark,
                  ),
                  Expanded(
                    child: Text(
                      S.monthTitle(_month.year, _month.month),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: S.nextMonth,
                    onPressed: canNext ? () => _shift(1, first, last) : null,
                    icon: const Icon(Icons.chevron_right_rounded),
                    color: AppColors.pinkDark,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final label in S.weekdays)
                    Expanded(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              _Grid(
                month: _month,
                today: today,
                activation: _activation(store.history.activatedOn),
                selected: _selected,
                progressFor: store.progressFor,
                onSelect: (day) => setState(() => _selected = day),
              ),
              const SizedBox(height: 12),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: AppColors.tealDark,
                  ),
                  SizedBox(width: 4),
                  Text(
                    S.calendarFull,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                  SizedBox(width: 16),
                  _HalfCircle(size: 14),
                  SizedBox(width: 4),
                  Text(
                    S.calendarPartial,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
              if (selected != null && selected.total > 0) ...[
                const SizedBox(height: 8),
                Text(
                  S.dayTasksProgress(selected.completed, selected.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.pinkDark,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Grid extends StatelessWidget {
  const _Grid({
    required this.month,
    required this.today,
    required this.activation,
    required this.selected,
    required this.progressFor,
    required this.onSelect,
  });

  final DateTime month;
  final DateTime today;
  final DateTime activation;
  final String? selected;
  final DayProgress? Function(String day) progressFor;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final first = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final leading = first.weekday - 1;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();

    return Column(
      children: [
        for (var row = 0; row < rows; row++)
          Row(
            children: [
              for (var col = 0; col < 7; col++)
                Expanded(
                  child: _cell(row * 7 + col, leading, daysInMonth),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(int index, int leading, int daysInMonth) {
    final dayNum = index - leading + 1;
    if (dayNum < 1 || dayNum > daysInMonth) {
      return const SizedBox(height: 44);
    }

    final date = DateTime(month.year, month.month, dayNum);
    final stamp = stampFromDate(date);
    final inRange = !date.isBefore(activation) && !date.isAfter(today);
    final isToday = stamp == stampFromDate(today);
    final isSelected = stamp == selected;
    final progress = inRange ? progressFor(stamp) : null;

    return Padding(
      padding: const EdgeInsets.all(2),
      child: Material(
        color: isSelected ? AppColors.blush : Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: inRange ? () => onSelect(stamp) : null,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 44,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isToday ? AppColors.pink : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNum',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: inRange ? AppColors.ink : AppColors.blush,
                    ),
                  ),
                  SizedBox(
                    height: 16,
                    child: Center(child: _Mark(progress: progress)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({this.progress});

  final DayProgress? progress;

  @override
  Widget build(BuildContext context) {
    if (progress == null) return const SizedBox.shrink();
    if (progress!.isFull) {
      return const Icon(
        Icons.check_circle_rounded,
        size: 16,
        color: AppColors.tealDark,
      );
    }
    if (progress!.isPartial) return const _HalfCircle(size: 14);
    return const SizedBox.shrink();
  }
}

class _HalfCircle extends StatelessWidget {
  const _HalfCircle({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: const CustomPaint(painter: _HalfCirclePainter()),
    );
  }
}

class _HalfCirclePainter extends CustomPainter {
  const _HalfCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outline = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final fill = Paint()..color = AppColors.goldDeep;
    canvas.drawCircle(rect.center, size.width / 2 - 1, outline);
    canvas.drawArc(
      rect.deflate(1),
      -math.pi / 2,
      math.pi,
      true,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
