use engine_core::factory::GameFactory;
use engine_core::game::GameType;
use engine_core::history::GameSnapshot;
use proptest::prelude::*;

proptest! {
    #[test]
    fn test_fuzz_json_deserialization(s in "\\PC*") {
        // Attempting to deserialize random UTF-8 strings should never panic
        let result: Result<GameSnapshot, _> = serde_json::from_str(&s);
        let _ = result;
    }

    #[test]
    fn test_fuzz_bytes_deserialization(bytes in proptest::collection::vec(any::<u8>(), 0..256)) {
        // Attempting to deserialize random byte arrays should never panic
        let result: Result<GameSnapshot, _> = serde_json::from_slice(&bytes);
        let _ = result;
    }

    #[test]
    fn test_fuzz_game_initialization(seed in any::<u64>(), type_idx in 0..10u8) {
        let game_type = match type_idx % 10 {
            0 => GameType::Klondike,
            1 => GameType::Spider,
            2 => GameType::FreeCell,
            3 => GameType::Pyramid,
            4 => GameType::Golf,
            5 => GameType::TriPeaks,
            6 => GameType::Yukon,
            7 => GameType::FortyThieves,
            8 => GameType::Canfield,
            _ => GameType::Scorpion,
        };

        // Engine creation with random seed must never panic
        let mut engine = GameFactory::create_game(game_type);
        engine.initialize(seed);
        assert!(!engine.piles().is_empty());

        // Snapshot roundtrip serialization must be losslessly exact
        let snapshot = GameSnapshot::new(engine.piles().to_vec(), 0, 0);
        let json = serde_json::to_string(&snapshot).expect("Serialization failed");
        let restored: GameSnapshot = serde_json::from_str(&json).expect("Deserialization failed");
        assert_eq!(snapshot, restored);
    }
}
