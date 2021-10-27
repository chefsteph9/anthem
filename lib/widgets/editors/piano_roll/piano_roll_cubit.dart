/*
  Copyright (C) 2021 Joshua Wade

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
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:plugin/generated/rid_api.dart';

part 'piano_roll_state.dart';

class PianoRollCubit extends Cubit<PianoRollState> {
  // ignore: unused_field
  late final StreamSubscription<PostedReply> _updateActivePatternSub;
  // ignore: unused_field
  late final StreamSubscription<PostedReply> _updateActiveInstrumentSub;
  // ignore: unused_field
  late final StreamSubscription<PostedReply> _updateNotesSub;
  final Store _store = Store.instance;

  PianoRollCubit({required int projectID})
      : super(
          PianoRollState(
            projectID: projectID,
            pattern: null,
            ticksPerQuarter: Store.instance.projects
                .firstWhere((project) => project.id == projectID)
                .song
                .ticksPerQuarter,
            activeInstrumentID: null,
          ),
        ) {
    _updateActivePatternSub = rid.replyChannel.stream
        .where((event) =>
            event.type == Reply.ActivePatternSet ||
            event.type == Reply.NoteAdded ||
            event.type == Reply.NoteDeleted ||
            event.type == Reply.ActiveInstrumentSet)
        .listen(_updateActivePattern);
    _updateActiveInstrumentSub = rid.replyChannel.stream
        .where((event) =>
            event.type == Reply.ActiveInstrumentSet)
        .listen(_updateActiveInstrument);
  }

  _updateActivePattern(PostedReply _reply) {
    final project =
        _store.projects.firstWhere((project) => project.id == state.projectID);
    final patternID = project.song.activePatternId;
    Pattern? pattern;
    if (patternID != 0) {
      pattern = project.song.patterns
          .firstWhere((pattern) => pattern.id == patternID);
    }
    emit(PianoRollState(
      projectID: state.projectID,
      ticksPerQuarter: state.ticksPerQuarter,
      pattern: pattern,
      activeInstrumentID: state.activeInstrumentID,
    ));
  }

  _updateActiveInstrument(PostedReply _reply) {
    final project =
        _store.projects.firstWhere((project) => project.id == state.projectID);
    emit(PianoRollState(
      projectID: state.projectID,
      ticksPerQuarter: state.ticksPerQuarter,
      pattern: state.pattern,
      activeInstrumentID: project.song.activeInstrumentId,
    ));
  }

  Future<void> addNote({
    required int? channelID,
    required int key,
    required int velocity,
    required int length,
    required int offset,
  }) {
    if (state.pattern == null || channelID == null) {
      final completer = Completer();
      completer.complete();
      return completer.future;
    }

    final data = Map();

    data["key"] = key;
    data["velocity"] = velocity;
    data["length"] = length;
    data["offset"] = offset;

    return _store.msgAddNote(
        state.projectID, state.pattern!.id, channelID, json.encode(data));
  }
}
