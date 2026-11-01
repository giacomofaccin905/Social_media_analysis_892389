"""
Trasforma l'output di load_clubs() in DataFrame pandas, uno per club.

Per ogni club si ottengono due tabelle:

  panel   una riga per atleta e mese (n atleti x 12 mesi)
          club, node, wave, freq_run, time_run, freq_other, time_other, winter,
          kudos_out (kudos dati nel mese), kudos_in (kudos ricevuti nel mese),
          in_club (True dal mese di ingresso), gender, male, female, other,
          novice, start_year, entry_wave
          NaN = atleta non ancora nel club (come gli NA di R)

  edges   una riga per ogni arco dei kudos: club, wave, source, target
          (source ha dato almeno un kudos a target in quel mese)

`node` e `wave` partono da 1, come nei CSV.
"""
import numpy as np
import pandas as pd

from load_strava_clubs import BEHAVIOR_VARS, load_clubs


def club_panel(c, k):
    n, n_waves = c["freq_run"].shape

    panel = pd.DataFrame({
        "club": k,
        "node": np.repeat(np.arange(1, n + 1), n_waves),   # atleta 1 per 12 mesi, poi atleta 2, ...
        "wave": np.tile(np.arange(1, n_waves + 1), n),
    })
    for var in BEHAVIOR_VARS:
        panel[var] = c[var].reshape(-1)                     # (n, T) -> riga per riga

    kudos = c["kudos"]                                      # (n, n, T): [i, j, mese] = i -> j
    panel["kudos_out"] = np.nansum(kudos, axis=1).reshape(-1)   # somma sui destinatari
    panel["kudos_in"] = np.nansum(kudos, axis=0).reshape(-1)    # somma sui mittenti

    covariates = c["nodes"].drop(columns="club")
    panel = panel.merge(covariates, on="node", how="left")

    panel["in_club"] = panel["wave"] >= panel["entry_wave"]
    panel.loc[~panel["in_club"], ["kudos_out", "kudos_in"]] = np.nan   # non ancora nel club
    return panel


def club_edges(c, k):
    i, j, w = np.nonzero(np.nan_to_num(c["kudos"]) == 1)    # le celle NaN non sono archi
    return pd.DataFrame({"club": k, "wave": w + 1, "source": i + 1, "target": j + 1})


def build_frames(clubs):
    panels = {k: club_panel(c, k) for k, c in clubs.items()}
    edges = {k: club_edges(c, k) for k, c in clubs.items()}
    return panels, edges


if __name__ == "__main__":
    panels, edges = build_frames(load_clubs("export"))
    for k in panels:
        print(f"club {k}: panel {panels[k].shape}, archi {edges[k].shape}")
