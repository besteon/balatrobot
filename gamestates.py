import json
from datetime import datetime
import os


def cache_state(game_step, G):
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S%f")
    if not os.path.exists(f"gamestate_cache/{game_step}/"):
        os.makedirs(f"gamestate_cache/{game_step}/")
    filename = f"gamestate_cache/{game_step}/{timestamp}.json"
    with open(filename, "w") as f:
        f.write(json.dumps(G, indent=4))
