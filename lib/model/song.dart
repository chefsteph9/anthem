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
import 'dart:collection';
import 'dart:convert';

import 'package:anthem/commands/state_changes.dart';
import 'package:anthem/helpers/get_id.dart';
import 'package:anthem/model/pattern.dart';
import 'package:anthem/model/project.dart';
import 'package:json_annotation/json_annotation.dart';

part 'song.g.dart';

@JsonSerializable()
class SongModel {
  int id;
  int ticksPerQuarter = 96; // TODO
  Map<int, PatternModel> patterns;
  List<int> patternOrder;
  int? activePatternID;
  int? activeGeneratorID;

  @JsonKey(ignore: true)
  StreamController<StateChange>? _changeStreamController;

  @JsonKey(ignore: true)
  ProjectModel? _project;

  SongModel()
      : id = getID(),
        ticksPerQuarter = 96,
        patterns = HashMap(),
        patternOrder = [];

  factory SongModel.fromJson(Map<String, dynamic> json) =>
      _$SongModelFromJson(json);

  Map<String, dynamic> toJson() => _$SongModelToJson(this);

  @override
  String toString() => json.encode(toJson());

  void hydrate({
    required ProjectModel project,
    required StreamController<StateChange> changeStreamController,
  }) {
    _project = project;
    _changeStreamController = changeStreamController;
  }

  @override
  operator ==(Object other) {
    if (identical(other, this)) return true;

    return other is SongModel &&
        other.id == id &&
        other.ticksPerQuarter == ticksPerQuarter &&
        other.patterns == patterns &&
        other.patternOrder == patternOrder &&
        other.activePatternID == activePatternID &&
        other.activeGeneratorID == activeGeneratorID;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      ticksPerQuarter.hashCode ^
      patterns.hashCode ^
      patternOrder.hashCode ^
      activePatternID.hashCode ^
      activeGeneratorID.hashCode;

  void setActiveGenerator(int? generatorID) {
    activeGeneratorID = generatorID;
    _changeStreamController!.add(
        ActiveGeneratorSet(projectID: _project!.id, generatorID: generatorID));
  }

  void setActivePattern(int? patternID) {
    activePatternID = patternID;
    _changeStreamController!
        .add(ActivePatternSet(projectID: _project!.id, patternID: patternID));
  }
}