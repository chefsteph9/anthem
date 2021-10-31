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

part of 'generator_row_cubit.dart';

@immutable
class GeneratorRowState {
  final int generatorID;
  final int projectID;
  final int? patternID;
  final List<Note>? notes;

  GeneratorRowState({
    required this.generatorID,
    required this.projectID,
    required this.patternID,
    required this.notes,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeneratorRowState &&
          other.generatorID == generatorID &&
          other.projectID == projectID &&
          other.patternID == patternID &&
          other.notes == notes;
}