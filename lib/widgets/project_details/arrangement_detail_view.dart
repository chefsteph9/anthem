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
import 'package:anthem/widgets/basic/text_box_controlled.dart';
import 'package:anthem/widgets/project_details/arrangement_detail_view_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class ArrangementDetailView extends StatefulWidget {
  const ArrangementDetailView({Key? key}) : super(key: key);

  @override
  State<ArrangementDetailView> createState() => _ArrangementDetailViewState();
}

class _ArrangementDetailViewState extends State<ArrangementDetailView> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArrangementDetailViewCubit, ArrangementDetailViewState>(
        builder: (context, state) {
      final cubit = Provider.of<ArrangementDetailViewCubit>(context);

      return Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.panel.main,
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "ARRANGEMENT",
                  style: TextStyle(
                    color: Theme.text.main,
                    fontSize: 10,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 26,
                  child: ControlledTextBox(
                    text: state.arrangementName,
                    onChange: (text) {
                      cubit.setArrangementName(text);
                    },
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          const Expanded(child: SizedBox()),
        ],
      );
    });
  }
}
