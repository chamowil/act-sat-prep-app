#!/usr/bin/env python3
"""Builds assets/sat/questions/sat_rw_questions.json from the hand-written parts."""
import json, os, random, sys
sys.path.insert(0, os.path.dirname(__file__))
from sat_rw_part1 import PART1
from sat_rw_part2 import PART2

rng = random.Random(1600)
items = PART1 + PART2
rng.shuffle(items)
out = []
for i, (topic, diff, stim, prompt, correct, wrong, expl) in enumerate(items, 1):
    assert correct not in wrong and len(set(wrong)) == 3, prompt
    choices = wrong + [correct]
    rng.shuffle(choices)
    out.append({
        "id": f"sr-{i:03d}", "subject": "satrw", "topic": topic, "difficulty": diff,
        "stimulus": stim, "prompt": prompt, "choices": choices,
        "correctIndex": choices.index(correct), "explanation": expl,
    })
with open("assets/sat/questions/sat_rw_questions.json", "w") as fh:
    json.dump(out, fh, indent=1, ensure_ascii=False)
print(len(out), "RW questions")
