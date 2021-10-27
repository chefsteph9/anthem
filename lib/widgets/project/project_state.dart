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

part of 'project_cubit.dart';

@immutable
class ProjectState {
  final int id;
  final int? activeInstrumentID;
  final int? activeControllerID;

  ProjectState({
    required this.id,
    required this.activeInstrumentID,
    required this.activeControllerID,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectState &&
          other.id == id &&
          other.activeInstrumentID == activeInstrumentID &&
          other.activeControllerID == activeControllerID;
}