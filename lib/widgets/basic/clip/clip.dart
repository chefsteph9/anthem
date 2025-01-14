/*
  Copyright (C) 2022 Joshua Wade

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

// cspell:ignore ahsl

import 'package:anthem/widgets/basic/clip/clip_cubit.dart';
import 'package:anthem/widgets/basic/clip/clip_notes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../model/shared/anthem_color.dart';

class Clip extends StatelessWidget {
  final double ticksPerPixel;

  const Clip({Key? key, required this.ticksPerPixel}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ClipCubit, ClipState>(builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 15,
            decoration: BoxDecoration(
              color: getBaseColor(state.patternColor),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(3),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              state.patternName,
              style: TextStyle(
                color: getTextColor(state.patternColor),
                fontSize: 10,
              ),
            ),
          ),
          Expanded(
            child: Container(
                decoration: BoxDecoration(
                  color: getBaseColor(state.patternColor).withAlpha(0x66),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: ClipNotes(
                    color: getContentColor(state.patternColor),
                    timeViewStart: 0,
                    ticksPerPixel: ticksPerPixel,
                    notes: state.notes,
                  ),
                )),
          ),
        ],
      );
    });
  }
}

Color getBaseColor(AnthemColor color) {
  return HSLColor.fromAHSL(
    1,
    color.hue,
    (0.28 * color.saturationMultiplier).clamp(0, 1),
    (0.49 * color.lightnessMultiplier).clamp(0, 0.92),
  ).toColor();
}

Color getTextColor(AnthemColor color) {
  return HSLColor.fromAHSL(
    1,
    color.hue,
    (1 * color.saturationMultiplier).clamp(0, 1),
    (0.92 * color.lightnessMultiplier).clamp(0, 0.92),
  ).toColor();
}

Color getContentColor(AnthemColor color) {
  return HSLColor.fromAHSL(
    1,
    color.hue,
    (0.7 * color.saturationMultiplier).clamp(0, 1),
    (0.78 * color.lightnessMultiplier).clamp(0, 0.92),
  ).toColor();
}
