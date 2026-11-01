# Social_media_analysis_892389
# Can Social Networks Predict Running Behavior?
### Social Aggregation and Graph Neural Networks on Strava

Project by **Giacomo Faccin**, Università Ca' Foscari Venezia.

This project studies Strava as a social infrastructure for aggregation among runners, and tests to what extent an athlete's running behavior can be predicted from their social network. It combines **social network analysis** with **machine learning** (logistic regression, XGBoost and a GraphSAGE graph neural network).

## Research questions

1. To what extent does Strava work as an infrastructure for social aggregation?
2. Are high-status athletes more embedded or less bridging than other athletes, once the number of ties is taken into account?
3. Can an athlete's contacts improve the prediction of running behavior beyond the athlete's own history?

## Data

The analysis uses the reproduction package of Franken, Bekhuis and Tolsma (2022), *"Kudos make you run! How runners influence each other on the online social network Strava"*, Social Networks, 72.

- 5 Strava running clubs, **329 athletes**
- 12 monthly waves (2019), for a total of 3,948 athlete-month observations
- Running frequency and volume, other sport activity, and kudos exchanged within the club

| Club | 1 | 2 | 3 | 4 | 5 | Total |
|------|---|---|---|---|---|-------|
| Athletes | 27 | 58 | 159 | 9 | 76 | 329 |

Clubs 1 and 4 are small and are given limited weight in the interpretation.

> The original data belong to the authors of the cited study. Check the terms of the original reproduction package before redistributing them.

## Repository structure

| File | Description |
|------|-------------|
| `read_rsiena_data.R` | R script to read the original RSiena data |
| `export_clubdata_to_python.R` | R script that exports the club data to CSV files (in the `export/` folder) |
| `load_strava_clubs.py` | `load_clubs()` loads the CSV files and rebuilds, for each club, the athletes table, the kudos array (athlete × athlete × 12 waves) and the behavior matrices (athlete × 12 waves) |
| `club_dataframes.py` | `build_frames()` turns the arrays into pandas tables: a **panel** (one row per athlete and month) and an **edge list** (one row per kudos tie and month) |
| `Social_media_analysis_complete_corrected_Official_Giacomo_Faccin.ipynb` | Main notebook with the full analysis |
| `Social_media_analysis_peper_892389_Giacomo_Faccin_OFFICIAL.pdf` | Written report |
| `strava_presentation_Official_Giacomo_Faccin.pdf` | Presentation slides |

The two Python modules must be in the **same folder as the notebook**.

## Methods

The notebook is divided in three parts:

- **Part I: data and exploration.** Loading, panel and edge tables, exploratory analysis.
- **Part II: network analysis.** Three graphs are built: the directed weighted kudos graph, the undirected reciprocal graph (strong ties) and monthly snapshots. Measures include density, reciprocity, transitivity, components, path length and assortativity. Local bridges and embeddedness (overlap) are compared between high- and low-status athletes with **permutation tests** (5000 permutations, shuffling within club or within club and degree).
- **Part III: leakage-free prediction.** The target is whether weekly running frequency increases from month *t* to *t+1*. Features only use information up to *t*, validated with an automatic truncation test and an **expanding-window** temporal cross-validation (test months 6 to 11).

Models compared: base rate, logistic regression, XGBoost (with contact summaries) and GraphSAGE with three edge versions (real, none, randomly rewired). Evaluation uses ROC-AUC and PR-AUC with a paired bootstrap on athletes.

## Main results

- Kudos form cohesive and reciprocal communities in four of the five clubs (reciprocity 0.82 to 0.85). Club 3, the largest, is the exception.
- Once the number of ties is controlled, high-status athletes are neither more embedded nor less bridging than other athletes. The raw gap in bridging is explained by the many low-status athletes with a single tie.
- All models beat the base rate, but contacts add no information beyond the athlete's own recent history. The logistic regression (mean ROC-AUC 0.679) performs as well as or better than the models using the network.

This is a limit of social influence in this setting, not evidence of its absence: the data are small and observational, and the outcome is a coarse ordinal category. See the report for the full list of limitations.

## Installation and usage

Requirements: Python 3 and R (R is only needed to regenerate the CSV files).

```bash
pip install numpy pandas scikit-learn xgboost torch torch_geometric networkx matplotlib jupyter
```

1. (Optional) Run `export_clubdata_to_python.R` in R to create the `export/` folder with the CSV files.
2. Quick check of the loaders:
   ```bash
   python load_strava_clubs.py
   python club_dataframes.py
   ```
3. Open the notebook and run it from top to bottom:
   ```bash
   jupyter notebook Social_media_analysis_complete_corrected_Official_Giacomo_Faccin.ipynb
   ```

Minimal example in Python:

```python
from load_strava_clubs import load_clubs
from club_dataframes import build_frames

clubs = load_clubs("export")
panels, edges = build_frames(clubs)
print(panels[1].head())
```

## Reference

Franken, R., Bekhuis, H., & Tolsma, J. (2022). Kudos make you run! How runners influence each other on the online social network Strava. *Social Networks*, 72. https://doi.org/10.1016/j.socnet.2022.10.001

## Author

Giacomo Faccin, giacomo.faccin905@gmail.com

