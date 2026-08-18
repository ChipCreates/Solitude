use std::fmt;

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum EngineError {
    InvalidMove(String),
    PileNotFound(String),
    CardNotFound(String),
    InvalidState(String),
}

impl fmt::Display for EngineError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            EngineError::InvalidMove(msg) => write!(f, "Invalid move: {}", msg),
            EngineError::PileNotFound(msg) => write!(f, "Pile not found: {}", msg),
            EngineError::CardNotFound(msg) => write!(f, "Card not found: {}", msg),
            EngineError::InvalidState(msg) => write!(f, "Invalid state: {}", msg),
        }
    }
}

impl std::error::Error for EngineError {}
