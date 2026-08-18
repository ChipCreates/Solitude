import glob
import re

for filepath in glob.glob("crates/engine-core/src/games/*.rs"):
    if filepath.endswith("mod.rs") or filepath.endswith("factory.rs"):
        continue
    
    with open(filepath, "r") as f:
        content = f.read()
    
    target = re.search(r'impl GameRules for [a-zA-Z]+ \{', content)
    if target:
        insertion_point = target.end()
        code_to_insert = """
    fn snapshot_history(&self) -> History {
        self.history.clone()
    }
    fn restore_history(&mut self, history: History) {
        self.history = history;
    }
"""
        new_content = content[:insertion_point] + code_to_insert + content[insertion_point:]
        with open(filepath, "w") as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"Failed in {filepath}")
