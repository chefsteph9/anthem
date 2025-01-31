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

import 'dart:async';

import 'package:anthem/commands/pattern_commands.dart';
import 'package:anthem/commands/project_commands.dart';
import 'package:anthem/commands/state_changes.dart';
import 'package:anthem/helpers/id.dart';
import 'package:anthem/model/pattern/pattern.dart';
import 'package:anthem/model/project.dart';
import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'pattern_editor_state.dart';
part 'pattern_editor_cubit.freezed.dart';

class PatternEditorCubit extends Cubit<PatternEditorState> {
  final ProjectModel project;

  late final StreamSubscription<List<StateChange>> _stateChangeStream;

  @override
  Future<void> close() async {
    await _stateChangeStream.cancel();

    return super.close();
  }

  PatternEditorCubit({required this.project})
      : super(PatternEditorState(projectID: project.id)) {
    _stateChangeStream = project.stateChangeStream.listen(_onModelChanged);
  }

  _onModelChanged(List<StateChange> changes) {
    var updateActivePattern = false;
    var updatePatternList = false;
    var updateGeneratorList = false;

    for (final change in changes) {
      change.whenOrNull(
        project: (change) {
          change.mapOrNull(
            activePatternChanged: (change) => updateActivePattern = true,
          );
        },
        pattern: (change) {
          change.mapOrNull(
            patternAdded: (change) => updatePatternList = true,
            patternDeleted: (change) => updatePatternList = true,
            patternNameChanged: (change) => updatePatternList = true,
          );
        },
        generator: (change) {
          change.mapOrNull(
            generatorAdded: (change) => updateGeneratorList = true,
            generatorRemoved: (change) => updateGeneratorList = true,
          );
        },
      );
    }

    PatternEditorState? newState;

    if (updateActivePattern) {
      newState = (newState ?? state).copyWith(
        activePatternID: project.song.activePatternID,
      );
    }

    if (updatePatternList) {
      newState = (newState ?? state).copyWith(
          patternList: project.song.patternOrder
              .map(
                (id) => PatternListItem(
                    id: id, name: project.song.patterns[id]?.name ?? ""),
              )
              .toList());
    }

    if (updateGeneratorList) {
      newState = (newState ?? state).copyWith(
        controllers: project.controllers.map(
            (key, value) => MapEntry(key, GeneratorListItem(id: value.id))),
        generatorIDList: project.generatorList,
        instruments: project.instruments.map(
            (key, value) => MapEntry(key, GeneratorListItem(id: value.id))),
      );
    }

    if (newState != null) {
      emit(newState);
    }
  }

  ID addPattern([String? name]) {
    if (name == null) {
      var patternNumber = state.patternList.length;

      final existingNames = state.patternList.map((pattern) => pattern.name);

      do {
        patternNumber++;
        name = "Pattern $patternNumber";
      } while (existingNames.contains(name));
    }

    final patternModel = PatternModel.create(name: name, project: project);

    project.execute(
      AddPatternCommand(
        project: project,
        pattern: patternModel,
        index: project.song.patternOrder.length,
      ),
    );

    project.song.setActivePattern(patternModel.id);

    return patternModel.id;
  }

  void deletePattern(ID patternID) {
    project.execute(DeletePatternCommand(
      project: project,
      pattern: project.song.patterns[patternID]!,
      index: project.song.patternOrder.indexOf(patternID),
    ));
  }

  void addInstrument(String name, Color color) {
    project.execute(AddInstrumentCommand(
      project: project,
      instrumentID: getID(),
      name: name,
      color: color,
    ));
  }

  void addController(String name, Color color) {
    project.execute(AddControllerCommand(
      project: project,
      controllerID: getID(),
      name: name,
      color: color,
    ));
  }

  void removeGenerator(ID id) {
    throw UnimplementedError();
  }

  void setActivePattern(ID? id) {
    project.song.setActivePattern(id);
  }
}
