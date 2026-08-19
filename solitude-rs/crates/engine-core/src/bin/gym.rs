use engine_core::factory::GameFactory;
use engine_core::game::GameType;
use engine_core::solver::mcts::MctsSolver;
use engine_core::solver::{SolverContext, SolverEngine};
use std::time::Instant;

/// Headless Rust Gym for Machine Learning Heuristic Tuning
/// This binary strips out WASM and UI bindings to run Solitaire games at maximum possible CPU speed.
/// It is designed to be used with a Genetic Algorithm to automatically tune heuristic weights.

fn main() {
    println!("🏎️ Starting Bugatti Chiron Headless Gym...");
    
    let mut game = GameFactory::create_game(GameType::Spider);
    let seed = 42;
    game.initialize(seed);

    let start_time = Instant::now();
    let mut moves_made = 0;
    
    println!("Training agent on Spider Solitaire (Seed: {})", seed);
    
    loop {
        if game.check_win() {
            println!("Win achieved in {} moves!", moves_made);
            break;
        }

        // Test MCTS Solver performance natively
        let best_move = MctsSolver::find_best_move(game.as_mut(), 1000);
        
        match best_move {
            Some(m) => {
                if m.cards.is_empty() {
                    let _ = game.tap_stock();
                } else {
                    let _ = game.execute_move(m.from, m.to, &m.cards);
                }
                moves_made += 1;
            }
            None => {
                // Try fallback to standard BFS with caching
                match SolverEngine::find_best_move(game.as_mut(), SolverContext::AutoPlay) {
                    Some(m) => {
                        if m.cards.is_empty() {
                            let _ = game.tap_stock();
                        } else {
                            let _ = game.execute_move(m.from, m.to, &m.cards);
                        }
                        moves_made += 1;
                    }
                    None => {
                        println!("Agent got stuck at move {}. Fitness score: {}", moves_made, game.heuristic_score());
                        break;
                    }
                }
            }
        }
    }
    
    let duration = start_time.elapsed();
    println!("Simulation completed in {:?}", duration);
    println!("To implement the full Genetic Algorithm, expand this loop to spawn 100 agents, vary their heuristic weights slightly, and cross-breed the agents with the highest fitness scores.");
}
