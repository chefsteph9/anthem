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

use std::collections::HashMap;

use rid::RidStore;

use crate::commands::command::Command;
use crate::engine_bridge::EngineBridge;
use crate::message_handlers::pattern_message_handler;
use crate::message_handlers::project_message_handler;
use crate::message_handlers::store_message_handler;
use crate::model::project::Project;

use super::command_queue::CommandQueue;
use super::journal_page_accumulator::JournalPageAccumulator;

#[rid::store]
#[rid::structs(Project)]
#[derive(rid::Config)]
pub struct Store {
    pub projects: HashMap<u64, Project>,
    pub project_order: Vec<u64>,
    pub active_project_id: u64,

    // Undo/redo vectors for each project
    #[rid(skip)]
    pub command_queues: HashMap<u64, CommandQueue>,

    // Current journal page accumulator for each project
    #[rid(skip)]
    pub journal_page_accumulators: HashMap<u64, JournalPageAccumulator>,

    // Engine process wrappers for each project
    #[rid(skip)]
    pub engines: HashMap<u64, EngineBridge>,
}

impl Store {
    pub fn push_command(&mut self, project_id: u64, command: Box<dyn Command>) {
        self.command_queues
            .get_mut(&project_id)
            .unwrap()
            .push_command(command);
    }
}

impl RidStore<Msg> for Store {
    fn create() -> Self {
        Self {
            projects: HashMap::new(),
            project_order: Vec::new(),
            active_project_id: 0,
            command_queues: HashMap::new(),
            journal_page_accumulators: HashMap::new(),
            engines: HashMap::new(),
        }
    }

    fn update(&mut self, req_id: u64, msg: Msg) {
        let handled = [
            store_message_handler(self, req_id, &msg),
            project_message_handler(self, req_id, &msg),
            pattern_message_handler(self, req_id, &msg),
        ]
        .iter()
        .fold(false, |a, b| a || *b);

        if !handled {
            panic!("message not handled");
        }
    }
}

#[rid::message(Reply)]
#[derive(Debug)]
pub enum Msg {
    //
    // Store
    //
    Init,
    NewProject,
    SetActiveProject(u64),
    CloseProject(u64),
    SaveProject(u64, String),
    LoadProject(String),
    Undo(u64),
    Redo(u64),

    // All commands sent between a journal start and journal commit will be
    // batched into a single undo/redo operation
    JournalStartEntry(u64),
    JournalCommitEntry(u64),

    //
    // Project
    //
    AddInstrument(u64, String, u32),    // project ID, name, color
    AddController(u64, String, u32),    // project ID, name, color
    RemoveGenerator(u64, u64),
    SetActivePattern(u64, u64),    // project ID, pattern ID (0 means none)
    SetActiveInstrument(u64, u64), // project ID, instrument ID (0 means none)
    SetActiveController(u64, u64), // project ID, controller ID (0 means none)

    //
    // Pattern
    //
    AddPattern(u64, String),                // project ID, pattern name
    DeletePattern(u64, u64),                // project ID, pattern ID
    AddNote(u64, u64, u64, String),         // project ID, pattern ID, insrument ID, note as JSON
    DeleteNote(u64, u64, u64, u64),         // project ID, pattern ID, insrument ID, note ID
    MoveNote(u64, u64, u64, u64, u64, u64), // project ID, pattern ID, insrument ID, note ID, new key value, new offset
    ResizeNote(u64, u64, u64, u64, u64), // project ID, pattern ID, insrument ID, note ID, new length
}

// TODO: Some commands are destructive beyond what they can repair,
// specifically pattern and generator removal as of writing.

#[rid::reply]
#[derive(Clone, Debug)]
pub enum Reply {
    //
    // Special
    //
    NothingChanged(u64),

    //
    // Store
    //
    NewProjectCreated(u64, String),
    ActiveProjectChanged(u64, String),
    ProjectClosed(u64),
    ProjectSaved(u64),
    ProjectLoaded(u64, String),
    JournalEntryStarted(u64),
    JournalEntryCommitted(u64),

    //
    // Project
    //
    InstrumentAdded(u64),
    ControllerAdded(u64),
    GeneratorRemoved(u64),
    ActivePatternSet(u64),
    ActiveInstrumentSet(u64),
    ActiveControllerSet(u64),

    //
    // Pattern
    //
    PatternAdded(u64),
    PatternDeleted(u64),
    NoteAdded(u64, String),   // { "generatorID": u64, "patternID": u64 }
    NoteDeleted(u64, String), // { "generatorID": u64, "patternID": u64 }
    NoteMoved(u64, String),   // { "generatorID": u64, "patternID": u64 }
    NoteResized(u64, String), // { "generatorID": u64, "patternID": u64 }
}
