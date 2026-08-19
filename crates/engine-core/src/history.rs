use crate::pile::Pile;
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub struct GameSnapshot {
    pub piles: Vec<Pile>,
    pub move_count: u32,
    pub stock_recycle_count: u32,
}

impl GameSnapshot {
    pub fn new(piles: Vec<Pile>, move_count: u32, stock_recycle_count: u32) -> Self {
        Self {
            piles,
            move_count,
            stock_recycle_count,
        }
    }
}

#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct History {
    past: Vec<GameSnapshot>,
    future: Vec<GameSnapshot>,
}

impl History {
    pub fn new() -> Self {
        Self {
            past: Vec::new(),
            future: Vec::new(),
        }
    }

    pub fn push(&mut self, snapshot: GameSnapshot) {
        self.past.push(snapshot);
        self.future.clear();
    }

    pub fn undo(&mut self, current: GameSnapshot) -> Option<GameSnapshot> {
        if let Some(previous) = self.past.pop() {
            self.future.push(current);
            Some(previous)
        } else {
            None
        }
    }

    pub fn redo(&mut self, current: GameSnapshot) -> Option<GameSnapshot> {
        if let Some(next) = self.future.pop() {
            self.past.push(current);
            Some(next)
        } else {
            None
        }
    }

    pub fn can_undo(&self) -> bool {
        !self.past.is_empty()
    }

    pub fn can_redo(&self) -> bool {
        !self.future.is_empty()
    }

    pub fn clear(&mut self) {
        self.past.clear();
        self.future.clear();
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::pile::{Pile, PileType};

    #[test]
    fn test_history_undo_redo() {
        let mut history = History::new();

        let s1 = GameSnapshot::new(vec![Pile::new(PileType::Tableau, 0)], 0, 0);
        let s2 = GameSnapshot::new(vec![Pile::new(PileType::Tableau, 0)], 1, 0);
        let s3 = GameSnapshot::new(vec![Pile::new(PileType::Tableau, 0)], 2, 0);

        history.push(s1.clone());
        history.push(s2.clone());

        // Undo from s3 -> s2
        let previous = history.undo(s3.clone());
        assert_eq!(previous, Some(s2.clone()));

        // Undo from s2 -> s1
        let previous2 = history.undo(s2.clone());
        assert_eq!(previous2, Some(s1.clone()));

        // Redo from s1 -> s2
        let next = history.redo(s1.clone());
        assert_eq!(next, Some(s2.clone()));
    }

    #[test]
    fn test_push_clears_future() {
        let mut history = History::new();

        let s1 = GameSnapshot::new(vec![], 1, 0);
        let s2 = GameSnapshot::new(vec![], 2, 0);
        let s3 = GameSnapshot::new(vec![], 3, 0);

        history.push(s1.clone());
        history.undo(s2.clone());
        assert!(history.can_redo());

        // Push new branch clears future
        history.push(s3);
        assert!(!history.can_redo());
    }
}
