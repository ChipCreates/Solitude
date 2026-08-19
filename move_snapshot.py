import os
import glob

for filepath in glob.glob("crates/engine-core/src/games/*.rs"):
    if filepath.endswith("mod.rs") or filepath.endswith("factory.rs"):
        continue
    
    with open(filepath, "r") as f:
        content = f.read()
    
    # We want to find the snapshot() and restore() blocks and move them into the impl GameRules block.
    # Actually, if we just remove them from `impl XGame {` and put them in `impl GameRules for XGame {`, that's enough.
    
    import re
    
    snapshot_pattern = re.compile(r'(\s+fn snapshot\(&self\) -> GameSnapshot \{.*?\n\s+\})', re.DOTALL)
    restore_pattern = re.compile(r'(\s+fn restore\(&mut self, snapshot: GameSnapshot\) \{.*?\n\s+\})', re.DOTALL)
    
    snap_match = snapshot_pattern.search(content)
    rest_match = restore_pattern.search(content)
    
    if snap_match and rest_match:
        snap_code = snap_match.group(1)
        rest_code = rest_match.group(1)
        
        # remove them from original place
        new_content = content.replace(snap_code, "")
        new_content = new_content.replace(rest_code, "")
        
        # add them to GameRules impl
        # find `impl GameRules for`
        
        target = re.search(r'impl GameRules for [a-zA-Z]+ \{', new_content)
        if target:
            insertion_point = target.end()
            final_content = new_content[:insertion_point] + snap_code + rest_code + new_content[insertion_point:]
            
            with open(filepath, "w") as f:
                f.write(final_content)
            print(f"Updated {filepath}")
        else:
            print(f"Failed to find GameRules impl in {filepath}")
    else:
        print(f"Failed to find snapshot/restore in {filepath}")

