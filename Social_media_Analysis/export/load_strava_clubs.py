"""
Carica in Python i CSV creati da export_clubdata_to_python.R e ricostruisce,
per ogni club, gli stessi oggetti che esistevano in clubdata.RData:

    nodes        DataFrame (un record per atleta: gender, novice, start_year, entry_wave)
    kudos        array (n, n, T)  1 = arco i -> j nel mese w; NaN = atleta non ancora nel club
    freq_run     array (n, T)     volte a settimana (NaN se non ancora nel club)
    time_run     array (n, T)     ore a settimana
    freq_other   array (n, T)     bici + altre attività, volte a settimana
    time_other   array (n, T)     bici + altre attività, ore a settimana
    winter       array (n, T)     1 nei mesi invernali (gen, feb, dic nei dati originali)
    friendship   array (f, f)     rete "segui" (una sola rilevazione), indici propri
    friendship_aligned  bool      True solo se la rete "segui" ha gli stessi nodi dei kudos

Indici: nel CSV atleti e mesi partono da 1 (come in R); qui gli array usano
l'indicizzazione di Python (0 = primo atleta, 0 = primo mese).
"""
from pathlib import Path

import numpy as np
import pandas as pd

BEHAVIOR_VARS = ["freq_run", "time_run", "freq_other", "time_other", "winter"]


def load_clubs(export_dir="export"):
    d = Path(export_dir)
    clubs = pd.read_csv(d / "clubs.csv")
    nodes = pd.read_csv(d / "nodes.csv")
    behavior = pd.read_csv(d / "behavior_long.csv")
    kudos_edges = pd.read_csv(d / "kudos_edges.csv")
    f_nodes = pd.read_csv(d / "friendship_nodes.csv")
    f_edges = pd.read_csv(d / "friendship_edges.csv")

    out = {}
    for row in clubs.itertuples(index=False):
        k, n, n_waves = int(row.club), int(row.netsize), int(row.n_waves)

        club_nodes = nodes[nodes.club == k].sort_values("node").reset_index(drop=True)
        entry_wave = club_nodes["entry_wave"].to_numpy()

        # --- comportamento: da formato lungo a matrici (n, T) ---
        b = behavior[behavior.club == k]
        ni, wi = b["node"].to_numpy() - 1, b["wave"].to_numpy() - 1
        arrays = {}
        for var in BEHAVIOR_VARS:
            m = np.full((n, n_waves), np.nan)
            m[ni, wi] = b[var].to_numpy(dtype=float)
            arrays[var] = m

        # --- kudos: da lista di archi ad array (n, n, T) ---
        kudos = np.zeros((n, n, n_waves))
        e = kudos_edges[kudos_edges.club == k]
        kudos[e["source"].to_numpy() - 1, e["target"].to_numpy() - 1, e["wave"].to_numpy() - 1] = 1
        for i, ew in enumerate(entry_wave):          # atleta assente prima del suo mese di ingresso
            if ew > 1:
                kudos[i, :, : ew - 1] = np.nan
                kudos[:, i, : ew - 1] = np.nan

        # --- rete "segui" ---
        fsize = int(row.friendship_size)
        friendship = np.zeros((fsize, fsize))
        fe = f_edges[f_edges.club == k]
        friendship[fe["source"].to_numpy() - 1, fe["target"].to_numpy() - 1] = fe["weight"].to_numpy()

        out[k] = {
            "nodes": club_nodes,
            "kudos": kudos,
            **arrays,
            "friendship": friendship,
            "friend_ids": f_nodes[f_nodes.club == k].sort_values("fnode")["friend_id"].tolist(),
            "friendship_aligned": bool(row.friendship_aligned),
        }
    return out


def save_npz(clubs, folder="export_npz"):
    """Salva ogni club in un file .npz (si ricarica con np.load, senza i CSV)."""
    Path(folder).mkdir(exist_ok=True)
    for k, c in clubs.items():
        arrays = {name: c[name] for name in ["kudos", "friendship", *BEHAVIOR_VARS]}
        np.savez_compressed(Path(folder) / f"club{k}.npz", **arrays)


if __name__ == "__main__":
    clubs = load_clubs("export")
    for k, c in clubs.items():
        print(f"Club {k}: atleti={len(c['nodes'])}, kudos={c['kudos'].shape}, "
              f"freq_run={c['freq_run'].shape}, friendship={c['friendship'].shape}, "
              f"allineata={c['friendship_aligned']}")
