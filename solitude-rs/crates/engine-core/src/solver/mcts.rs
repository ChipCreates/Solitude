use crate::game::{GameRules, HintMove};
use crate::history::GameSnapshot;
use crate::pile::PileType;
use std::collections::HashMap;

/// Monte Carlo Tree Search (MCTS) Solver
/// This algorithm builds a tree of possible futures by balancing Exploration (trying new moves)
/// and Exploitation (focusing on moves with high heuristic scores).
/// It evaluates leaf nodes using the heuristic_score instead of full random rollouts,
/// akin to PUCT used in AlphaZero.

pub struct MctsSolver;

struct Node {
    parent: Option<usize>,
    move_taken: Option<HintMove>,
    children: Vec<usize>,
    untried_moves: Vec<HintMove>,
    visits: u32,
    total_score: f64,
    is_terminal: bool,
}

impl MctsSolver {
    pub fn find_best_move(game: &mut dyn GameRules, max_iterations: usize) -> Option<HintMove> {
        let initial_snapshot = game.snapshot();
        let initial_history = game.snapshot_history();
        
        let untried = game.get_available_moves();
        let is_terminal = untried.is_empty() || game.check_win();
        
        let mut nodes = Vec::with_capacity(max_iterations);
        nodes.push(Node {
            parent: None,
            move_taken: None,
            children: Vec::new(),
            untried_moves: untried,
            visits: 0,
            total_score: 0.0,
            is_terminal,
        });

        for _ in 0..max_iterations {
            game.restore(initial_snapshot.clone());
            game.restore_history(initial_history.clone());

            // 1. Selection
            let mut node_idx = 0;
            while nodes[node_idx].untried_moves.is_empty() && !nodes[node_idx].children.is_empty() {
                // Select child using UCT
                let mut best_uct = f64::NEG_INFINITY;
                let mut best_child = 0;
                let parent_visits = nodes[node_idx].visits as f64;
                
                for &child_idx in &nodes[node_idx].children {
                    let child = &nodes[child_idx];
                    let exploitation = child.total_score / (child.visits as f64);
                    // Standard UCT constant C = sqrt(2), tuned for heuristic scale
                    let exploration = 100.0 * (parent_visits.ln() / (child.visits as f64)).sqrt();
                    let uct = exploitation + exploration;
                    
                    if uct > best_uct {
                        best_uct = uct;
                        best_child = child_idx;
                    }
                }
                
                node_idx = best_child;
                // Apply move to state
                if let Some(m) = &nodes[node_idx].move_taken {
                    if m.cards.is_empty() && m.from.kind == PileType::Stock {
                        let _ = game.tap_stock();
                    } else {
                        let _ = game.execute_move(m.from, m.to, &m.cards);
                    }
                }
            }

            // 2. Expansion
            if !nodes[node_idx].untried_moves.is_empty() && !nodes[node_idx].is_terminal {
                let m = nodes[node_idx].untried_moves.pop().unwrap();
                
                // Apply the move
                if m.cards.is_empty() && m.from.kind == PileType::Stock {
                    let _ = game.tap_stock();
                } else {
                    let _ = game.execute_move(m.from, m.to, &m.cards);
                }
                
                let untried = game.get_available_moves();
                let is_term = untried.is_empty() || game.check_win();
                
                let child_idx = nodes.len();
                nodes.push(Node {
                    parent: Some(node_idx),
                    move_taken: Some(m),
                    children: Vec::new(),
                    untried_moves: untried,
                    visits: 0,
                    total_score: 0.0,
                    is_terminal: is_term,
                });
                
                nodes[node_idx].children.push(child_idx);
                node_idx = child_idx;
            }

            // 3. Simulation (Heuristic Rollout)
            // Instead of full random playout which is chaotic in Solitaire, we evaluate the immediate heuristic
            // If it's a win, give max score
            let score = if game.check_win() {
                10_000.0
            } else {
                game.heuristic_score() as f64
            };

            // 4. Backpropagation
            let mut current = Some(node_idx);
            while let Some(idx) = current {
                nodes[idx].visits += 1;
                nodes[idx].total_score += score;
                current = nodes[idx].parent;
            }
        }

        game.restore(initial_snapshot);
        game.restore_history(initial_history);

        // Pick the best move from the root's children (most visited)
        let mut most_visits = 0;
        let mut best_move = None;
        
        for &child_idx in &nodes[0].children {
            if nodes[child_idx].visits > most_visits {
                most_visits = nodes[child_idx].visits;
                best_move = nodes[child_idx].move_taken.clone();
            }
        }
        
        best_move
    }
}
