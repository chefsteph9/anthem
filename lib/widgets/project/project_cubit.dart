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

import 'package:anthem/commands/state_changes.dart';
import 'package:anthem/helpers/id.dart';
import 'package:anthem/model/project.dart';
import 'package:anthem/model/store.dart';
import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'project_state.dart';
part 'project_cubit.freezed.dart';

class ProjectCubit extends Cubit<ProjectState> {
  late final ProjectModel project;

  late final StreamSubscription<List<StateChange>> _stateChangeStream;

  ProjectCubit({required ID id}) : super(ProjectState(id: id)) {
    project = Store.instance.projects[id]!;
    _stateChangeStream = project.stateChangeStream.listen(_onModelChanged);
  }

  @override
  Future<void> close() async {
    await _stateChangeStream.cancel();

    return super.close();
  }

  void _onModelChanged(List<StateChange> changes) {
    var didSelectedDetailViewChange = false;

    for (final change in changes) {
      change.whenOrNull(
        project: (projectChange) {
          projectChange.mapOrNull(
            selectedDetailViewChanged: (change) =>
                didSelectedDetailViewChange = true,
          );
        },
      );
    }

    ProjectState? newState;

    if (didSelectedDetailViewChange) {
      newState = (newState ?? state).copyWith(
        isDetailViewSelected: project.isDetailViewSelected,
        selectedDetailView: project.selectedDetailView,
      );
    }

    if (newState != null) {
      emit(newState);
    }
  }

  void undo() {
    project.undo();
  }

  void redo() {
    project.redo();
  }

  void journalStartEntry() {
    project.startJournalPage();
  }

  void journalCommitEntry() {
    project.commitJournalPage();
  }

  void setIsProjectExplorerVisible(bool visible) =>
      emit(state.copyWith(isProjectExplorerVisible: visible));
  void setIsPatternEditorVisible(bool visible) =>
      emit(state.copyWith(isPatternEditorVisible: visible));
  void setActiveGeneratorID(ID? id) => project.song.setActiveGenerator(id);
  void setActiveDetailView(bool isVisible, [DetailViewKind? detailView]) {
    project.selectedDetailView = detailView;
    project.isDetailViewSelected = isVisible;
  }

  void setActiveEditor(EditorKind editor) =>
      emit(state.copyWith(selectedEditor: editor));
}
