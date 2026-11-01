# ==============================================================================
# Esporta clubdata.RData in file CSV "tidy" leggibili da Python, SENZA perdere
# informazione. Usa solo R base (non serve RSiena).
#
# Perché clubdata.RData e non i file clubdata_rsiena_*.RData:
#   gli oggetti RSiena sono costruiti a partire da clubdata (stesse matrici e
#   stessi vettori, impacchettati in una struttura S3 "siena"). Tutta
#   l'informazione sta già in clubdata.RData, che è una semplice lista di liste.
#   Il vecchio script perdeva i dati perché trattava gli oggetti siena come
#   vettori; qui si leggono direttamente gli array.
#
# Uso:
#   Rscript export_clubdata_to_python.R "C:/percorso/della/cartella"
#   oppure modifica `data_dir` qui sotto ed esegui il file in RStudio.
#
# File creati in <data_dir>/export/ :
#   clubs.csv              un record per club (dimensioni, controlli di coerenza)
#   nodes.csv              un record per atleta (genere, novice, wave di ingresso)
#   behavior_long.csv      un record per atleta e mese: freq_run, time_run,
#                          freq_other, time_other, winter (NA conservati)
#   kudos_edges.csv        lista di archi della rete dei kudos, per mese
#   friendship_nodes.csv   identificativi anonimi della rete "segui"
#   friendship_edges.csv   archi della rete "segui" (indici propri, vedi sotto)
# ==============================================================================

args <- commandArgs(trailingOnly = TRUE)
data_dir <- if (length(args) >= 1) {
  args[1]
} else {
  "C:/Users/Utente/OneDrive/Immagini/Documenti/Social_media_web_analysis"
}
output_dir <- file.path(data_dir, "export")

if (!dir.exists(data_dir)) stop("Cartella non trovata: ", data_dir)
dir.create(output_dir, showWarnings = FALSE, recursive = TRUE)

# ---- Carica i dati ----------------------------------------------------------
load(file.path(data_dir, "clubdata.RData"))          # crea l'oggetto `clubdata`
stopifnot(exists("clubdata"), is.list(clubdata))
cat("Club trovati:", length(clubdata), "\n")
cat("Elementi del primo club:", paste(names(clubdata[[1]]), collapse = ", "), "\n\n")

# array n x 1 x T  ->  matrice n x T  (l'ordine di memorizzazione coincide)
as_node_by_wave <- function(arr, n, n_waves) {
  stopifnot(length(arr) == n * n_waves)
  matrix(arr, nrow = n, ncol = n_waves)
}

# Ricostruisce la rete dei kudos dagli archi (per il controllo di coerenza)
rebuild_kudo <- function(edges_k, n, n_waves, entry_wave) {
  a <- array(0, dim = c(n, n, n_waves))
  if (nrow(edges_k) > 0) {
    a[cbind(edges_k$source, edges_k$target, edges_k$wave)] <- 1
  }
  for (i in which(entry_wave > 1)) {                  # atleta non ancora nel club
    for (w in seq_len(entry_wave[i] - 1)) {
      a[i, , w] <- NA
      a[, i, w] <- NA
    }
  }
  a
}

start_year_label <- c("<=2011", as.character(2012:2019))   # categorie di `novice`

nodes_l <- behav_l <- kudos_l <- fedges_l <- fnodes_l <- clubs_l <- list()

for (k in seq_along(clubdata)) {
  cl <- clubdata[[k]]
  n  <- cl$netsize
  kudo <- cl$kudo
  nw <- dim(kudo)[3]
  stopifnot(dim(kudo)[1] == n, dim(kudo)[2] == n)

  # ---- Atleti ---------------------------------------------------------------
  entry_wave <- sapply(cl$composition, function(z) z[1])   # mese di ingresso nel club
  nodes_l[[k]] <- data.frame(
    club = k, node = seq_len(n),
    gender = ifelse(cl$male == 1, "M", ifelse(cl$female == 1, "F",
                    ifelse(cl$other == 1, "O", NA))),
    male = cl$male, female = cl$female, other = cl$other,
    novice = cl$novice,                                     # categoria 1-9 (anno prima attività)
    start_year = start_year_label[cl$novice],
    entry_wave = entry_wave
  )

  # ---- Comportamento: un record per atleta e mese ---------------------------
  beh <- expand.grid(node = seq_len(n), wave = seq_len(nw))   # node varia più veloce
  beh$club       <- k
  beh$freq_run   <- as.vector(as_node_by_wave(cl$freq_run,   n, nw))  # volte a settimana (max 7)
  beh$time_run   <- as.vector(as_node_by_wave(cl$time_run,   n, nw))  # ore a settimana (max 7, club 5: 9)
  beh$freq_other <- as.vector(as_node_by_wave(cl$freq_other, n, nw))  # bici + altro
  beh$time_other <- as.vector(as_node_by_wave(cl$time_other, n, nw))
  beh$winter     <- as.vector(matrix(cl$winter, nrow = n, ncol = nw))
  behav_l[[k]] <- beh[, c("club", "node", "wave", "freq_run", "time_run",
                          "freq_other", "time_other", "winter")]

  # ---- Rete dei kudos: arco i -> j nel mese w se i ha dato almeno 1 kudos ---
  idx <- which(kudo == 1, arr.ind = TRUE)                 # le celle NA vengono ignorate
  kudos_l[[k]] <- data.frame(club = k, wave = idx[, 3], source = idx[, 1], target = idx[, 2])

  # ---- Rete "segui" (una sola rilevazione) ----------------------------------
  fr <- cl$friendship
  fsize <- nrow(fr)
  fidx <- which(!is.na(fr) & fr != 0, arr.ind = TRUE)
  fnodes_l[[k]] <- data.frame(club = k, fnode = seq_len(fsize),
                              friend_id = if (is.null(colnames(fr))) NA else colnames(fr))
  fedges_l[[k]] <- data.frame(club = k, source = fidx[, 1], target = fidx[, 2],
                              weight = fr[fidx])

  # ---- Controlli di coerenza ------------------------------------------------
  rebuilt <- rebuild_kudo(kudos_l[[k]], n, nw, entry_wave)
  kudo_ok <- identical(is.na(rebuilt), is.na(kudo)) &&
             all(rebuilt[!is.na(rebuilt)] == kudo[!is.na(kudo)])
  na_run_ok <- all(is.na(beh$freq_run) == (beh$wave < entry_wave[beh$node]))

  clubs_l[[k]] <- data.frame(
    club = k, netsize = n, n_waves = nw,
    friendship_size = fsize, friendship_aligned = (fsize == n),
    n_kudos_ties = nrow(kudos_l[[k]]),
    n_late_joiners = sum(entry_wave > 1),
    check_kudos_roundtrip = kudo_ok,
    check_na_matches_entry = na_run_ok
  )

  cat(sprintf("Club %d: %d atleti, %d mesi, %d archi kudos | rete 'segui': %d nodi%s | controlli: kudos %s, NA %s\n",
              k, n, nw, nrow(kudos_l[[k]]), fsize,
              ifelse(fsize == n, "", "  (NON allineata ai kudos!)"),
              ifelse(kudo_ok, "OK", "ATTENZIONE"), ifelse(na_run_ok, "OK", "ATTENZIONE")))
}

# ---- Scrittura ----------------------------------------------------------------
write_out <- function(lst, name) {
  df <- do.call(rbind, lst)
  rownames(df) <- NULL
  write.csv(df, file.path(output_dir, name), row.names = FALSE, na = "")
  cat("Scritto:", name, "-", nrow(df), "righe\n")
}
write_out(clubs_l,  "clubs.csv")
write_out(nodes_l,  "nodes.csv")
write_out(behav_l,  "behavior_long.csv")
write_out(kudos_l,  "kudos_edges.csv")
write_out(fnodes_l, "friendship_nodes.csv")
write_out(fedges_l, "friendship_edges.csv")

cat("\nFatto. File in:", output_dir, "\n")
if (any(!sapply(clubs_l, function(d) d$friendship_aligned))) {
  cat("\nNOTA: in alcuni club la rete 'segui' ha più nodi della rete dei kudos.\n",
      "Gli autori l'hanno costruita prima di togliere gli atleti entrati solo\n",
      "all'ultimo mese e non hanno salvato quali fossero: i suoi indici NON\n",
      "corrispondono a quelli di nodes.csv. Va usata con il proprio indice.\n")
}
