/*
  Copyright (C) 2021 - 2022 Joshua Wade

  This file is part of Anthem.

  Anthem is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  Anthem is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
  General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with Anthem. If not, see <https://www.gnu.org/licenses/>.
*/

// cspell:ignore relayout

import 'package:anthem/helpers/id.dart';
import 'package:anthem/model/shared/time_signature.dart';
import 'package:anthem/theme.dart';
import 'package:anthem/widgets/editors/shared/timeline/timeline_notifications.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

import '../helpers/time_helpers.dart';
import '../helpers/types.dart';
import 'timeline_cubit.dart';

class Timeline extends StatefulWidget {
  final AnimationController timeViewAnimationController;
  final Animation<double> timeViewStartAnimation;
  final Animation<double> timeViewEndAnimation;

  const Timeline({
    Key? key,
    required this.timeViewAnimationController,
    required this.timeViewStartAnimation,
    required this.timeViewEndAnimation,
  }) : super(key: key);

  @override
  State<Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> with TickerProviderStateMixin {
  double dragStartPixelValue = -1.0;
  double dragStartTimeViewStartValue = -1.0;
  double dragStartTimeViewEndValue = -1.0;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimelineCubit, TimelineState>(
      builder: (context, state) {
        return LayoutBuilder(builder: (context, constraints) {
          var timeView = context.watch<TimeView>();

          void handleScroll(double delta, double mouseX) {
            final timeViewWidth = timeView.width;
            final timeViewSizeChange = timeViewWidth * 0.008 * delta;

            final mouseCursorOffset = mouseX / constraints.maxWidth;

            var newStart =
                timeView.start - timeViewSizeChange * mouseCursorOffset;
            var newEnd =
                timeView.end + timeViewSizeChange * (1 - mouseCursorOffset);

            // Somewhat arbitrary, but a safeguard against zooming in too far
            if (newEnd < newStart + 10) {
              newEnd = newStart + 10;
            }

            final startOvershootCorrection = newStart < 0 ? -newStart : 0;

            newStart += startOvershootCorrection;
            newEnd += startOvershootCorrection;

            timeView.setStart(newStart);
            timeView.setEnd(newEnd);
          }

          var timelineLabels = state.timeSignatureChanges.inner
              .map(
                (change) => LayoutId(
                  id: change.offset,
                  child: TimelineLabel(
                    text:
                        "${change.timeSignature.numerator}/${change.timeSignature.denominator}",
                    id: change.id,
                    offset: change.offset,
                    timelineWidth: constraints.maxWidth,
                    stableBuildContext: context,
                  ),
                ),
              )
              .toList();

          return Listener(
            onPointerPanZoomUpdate: (event) {
              handleScroll(-event.panDelta.dy / 2, event.localPosition.dx);
            },
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                handleScroll(event.scrollDelta.dy, event.localPosition.dx);
              }
            },
            child: ClipRect(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    color: Theme.panel.accent,
                    child: ClipRect(
                      child: AnimatedBuilder(
                          animation: widget.timeViewAnimationController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: TimelinePainter(
                                timeViewStart: widget.timeViewStartAnimation.value,
                                timeViewEnd: widget.timeViewEndAnimation.value,
                                ticksPerQuarter: state.ticksPerQuarter,
                                defaultTimeSignature:
                                    state.defaultTimeSignature,
                                timeSignatureChanges:
                                    state.timeSignatureChanges.inner,
                              ),
                            );
                          }),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: widget.timeViewAnimationController,
                    builder: (context, child) {
                      return CustomMultiChildLayout(
                        delegate: TimeSignatureLabelLayoutDelegate(
                          timeSignatureChanges:
                              state.timeSignatureChanges.inner,
                          timeViewStart: widget.timeViewStartAnimation.value,
                          timeViewEnd: widget.timeViewEndAnimation.value,
                        ),
                        children: timelineLabels,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }
}

class TimeSignatureLabelLayoutDelegate extends MultiChildLayoutDelegate {
  TimeSignatureLabelLayoutDelegate({
    required this.timeSignatureChanges,
    required this.timeViewStart,
    required this.timeViewEnd,
  });

  List<TimeSignatureChangeModel> timeSignatureChanges;
  double timeViewStart;
  double timeViewEnd;

  @override
  void performLayout(Size size) {
    for (var change in timeSignatureChanges) {
      layoutChild(
        change.offset,
        BoxConstraints(
          maxWidth: size.width,
          maxHeight: size.height,
        ),
      );

      var x = timeToPixels(
        timeViewStart: timeViewStart,
        timeViewEnd: timeViewEnd,
        viewPixelWidth: size.width,
        time: change.offset.toDouble(),
      );

      positionChild(
          change.offset, Offset(x - _labelHandleMouseAreaPadding, 21));
    }
  }

  @override
  bool shouldRelayout(TimeSignatureLabelLayoutDelegate oldDelegate) {
    return oldDelegate.timeViewStart != timeViewStart ||
        oldDelegate.timeViewEnd != timeViewEnd ||
        oldDelegate.timeSignatureChanges != timeSignatureChanges;
  }
}

const _labelHandleWidth = 2.0;
const _labelHandleMouseAreaPadding = 5.0;

class TimelineLabel extends StatefulWidget {
  final String text;
  final ID id;
  final Time offset;
  final double timelineWidth;
  // We need to pass in the parent's build context, since our build context
  // doesn't stay valid during event handling.
  final BuildContext stableBuildContext;

  const TimelineLabel({
    Key? key,
    required this.text,
    required this.id,
    required this.offset,
    required this.timelineWidth,
    required this.stableBuildContext,
  }) : super(key: key);

  @override
  State<TimelineLabel> createState() => _TimelineLabelState();
}

class _TimelineLabelState extends State<TimelineLabel> {
  double pointerStart = 0;
  Time timeStart = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.passthrough,
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: _labelHandleMouseAreaPadding,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                color: const Color(0xFFFFFFFF).withOpacity(0.6),
                width: _labelHandleWidth,
                height: 21,
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(3),
                  ),
                ),
                padding: const EdgeInsets.only(left: 4, right: 4),
                height: 21,
                child: Text(
                  widget.text,
                  style: TextStyle(color: Theme.text.main),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          child: MouseRegion(
            cursor: SystemMouseCursors.resizeLeftRight,
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) {
                pointerStart = event.position.dx;
                timeStart = widget.offset;
                TimelineLabelPointerDownNotification(
                  time: widget.offset.toDouble(),
                  labelID: widget.id,
                  labelType: TimelineLabelType.timeSignatureChange,
                  viewWidthInPixels: widget.timelineWidth,
                ).dispatch(widget.stableBuildContext);
              },
              onPointerMove: (event) {
                final timeView = Provider.of<TimeView>(
                    widget.stableBuildContext,
                    listen: false);
                final time = (event.position.dx - pointerStart) *
                    timeView.width /
                    widget.timelineWidth;
                TimelineLabelPointerMoveNotification(
                  time: time,
                  labelID: widget.id,
                  labelType: TimelineLabelType.timeSignatureChange,
                  viewWidthInPixels: widget.timelineWidth,
                ).dispatch(widget.stableBuildContext);
              },
              onPointerUp: (event) {
                final timeView = Provider.of<TimeView>(
                    widget.stableBuildContext,
                    listen: false);
                final time = (event.position.dx - pointerStart) *
                    timeView.width /
                    widget.timelineWidth;
                TimelineLabelPointerUpNotification(
                  time: time,
                  labelID: widget.id,
                  labelType: TimelineLabelType.timeSignatureChange,
                  viewWidthInPixels: widget.timelineWidth,
                ).dispatch(widget.stableBuildContext);
              },
              child: const SizedBox(width: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class TimelinePainter extends CustomPainter {
  TimelinePainter({
    required this.timeViewStart,
    required this.timeViewEnd,
    required this.ticksPerQuarter,
    required this.defaultTimeSignature,
    required this.timeSignatureChanges,
  });

  final double timeViewStart;
  final double timeViewEnd;
  final int ticksPerQuarter;
  final TimeSignatureModel defaultTimeSignature;
  final List<TimeSignatureChangeModel> timeSignatureChanges;

  @override
  void paint(Canvas canvas, Size size) {
    var divisionChanges = getDivisionChanges(
      viewWidthInPixels: size.width,
      minPixelsPerSection: 32,
      snap: BarSnap(),
      defaultTimeSignature: defaultTimeSignature,
      timeSignatureChanges: timeSignatureChanges,
      ticksPerQuarter: ticksPerQuarter,
      timeViewStart: timeViewStart,
      timeViewEnd: timeViewEnd,
    );

    // Calculate a starting point that isn't the beginning, but is before the
    // start of the TimeView
    // var firstChangeOnScreen = divisionChanges[0];

    // var first = true;

    // for (final change in divisionChanges) {
    //   if (first) {
    //     first = false;
    //     continue;
    //   }

    //   if (timeViewStart < change.offset) {
    //     break;
    //   }

    //   firstChangeOnScreen = change;
    // }

    var i = 0;
    var timePtr = 0;
    var barNumber = divisionChanges[0].startLabel;

    barNumber += (timePtr /
            (divisionChanges[0].divisionRenderSize /
                divisionChanges[0].distanceBetween))
        .floor();

    while (timePtr < timeViewEnd) {
      // This shouldn't happen, but safety first
      if (i >= divisionChanges.length) break;

      final thisDivision = divisionChanges[i];
      var nextDivisionStart = 0x7FFFFFFFFFFFFFFF; // int max

      if (i < divisionChanges.length - 1) {
        nextDivisionStart = divisionChanges[i + 1].offset;
      }

      while (timePtr < nextDivisionStart && timePtr < timeViewEnd) {
        final x = timeToPixels(
          timeViewStart: timeViewStart,
          timeViewEnd: timeViewEnd,
          viewPixelWidth: size.width,
          time: timePtr.toDouble(),
        );

        // Don't draw numbers that are off-screen
        if (x >= -50) {
          TextSpan span = TextSpan(
            style: TextStyle(color: Theme.text.main),
            text: barNumber.toString(),
          );
          TextPainter textPainter = TextPainter(
            text: span,
            textAlign: TextAlign.left,
            textDirection: TextDirection.ltr,
          );
          textPainter.layout();
          // TODO: replace height constant?
          textPainter.paint(
            canvas,
            Offset(x, (21 - textPainter.size.height) / 2),
          );
        }

        timePtr += thisDivision.divisionRenderSize;
        barNumber += thisDivision.distanceBetween;

        // If this is true, then this is the last iteration of the inner loop
        if (timePtr >= nextDivisionStart) {
          timePtr = nextDivisionStart;
          barNumber = divisionChanges[i + 1].startLabel;
        }
      }

      i++;
    }
  }

  @override
  bool shouldRepaint(TimelinePainter oldDelegate) {
    return oldDelegate.timeViewStart != timeViewStart ||
        oldDelegate.timeViewEnd != timeViewEnd;
  }

  @override
  bool shouldRebuildSemantics(TimelinePainter oldDelegate) => false;
}
