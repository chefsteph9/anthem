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

import 'package:anthem/theme.dart';
import 'package:anthem/widgets/basic/color_picker.dart';
import 'package:anthem/widgets/basic/text_box_controlled.dart';
import 'package:anthem/widgets/project_details/pattern_detail_view_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class _Header extends StatelessWidget {
  final String text;

  const _Header(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: Theme.text.main,
        fontSize: 10,
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _Section extends StatelessWidget {
  final List<Widget> children;
  final String title;

  const _Section({Key? key, this.children = const [], required this.title})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.panel.main,
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              _Header(title),
              const SizedBox(height: 6),
            ] +
            children,
      ),
    );
  }
}

class PatternDetailView extends StatelessWidget {
  const PatternDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PatternDetailViewCubit, PatternDetailViewState>(
        builder: (context, state) {
      final cubit = Provider.of<PatternDetailViewCubit>(context);

      return Column(
        children: [
          _Section(
            title: "PATTERN",
            children: [
              SizedBox(
                height: 26,
                child: ControlledTextBox(
                  text: state.patternName,
                  onChange: (newName) => cubit.setPatternName(newName),
                ),
              ),
              const SizedBox(height: 6),
              ColorPicker(
                onChange: (color) {
                  cubit.setPatternColor(color);
                }, 
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Expanded(child: SizedBox()),
        ],
      );
    });
  }
}
