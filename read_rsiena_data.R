# ========================================
# LEGGI DATI RSIENA (NETWORK ANALYSIS)
# ========================================

cat("========================================\n")
cat("CONVERTITORE DATI RSIENA A CSV\n")
cat("========================================\n\n")

# Chiedi il percorso
cat("Inserisci il percorso della cartella con i file .RData\n")
cat("(es: C:/Users/Utente/OneDrive/Immagini/Documenti/Social_media_web_analysis)\n")
cat("Percorso: ")
data_dir <- readLines(n = 1)
data_dir <- trimws(data_dir)

if (!dir.exists(data_dir)) {
  cat("✗ Cartella non trovata:", data_dir, "\n")
  stop("Directory non trovata")
}

output_dir <- data_dir
cat("✓ Cartella trovata:", data_dir, "\n\n")

# Carica i file
file_clubdata <- file.path(data_dir, "clubdata.RData")
file_freq <- file.path(data_dir, "clubdata_rsiena_freq.RData")
file_vol <- file.path(data_dir, "clubdata_rsiena_vol.RData")

cat("Caricando i file...\n")
load(file_clubdata)
load(file_freq)
load(file_vol)
cat("✓ File caricati\n\n")

# ============================================
# 1. ELABORA CLUBDATA (Lista di reti)
# ============================================
cat("========================================\n")
cat("1. ELABORAZIONE CLUBDATA\n")
cat("========================================\n")

cat("Struttura: Lista di", length(clubdata), "reti (periodi temporali)\n\n")

# Estrai dati da ogni rete e combina in un unico dataframe
all_data <- data.frame()

for (net_idx in seq_along(clubdata)) {
  cat("  Rete", net_idx, "...")
  
  net <- clubdata[[net_idx]]
  
  # Estrai informazioni base
  netsize <- net$netsize
  
  # Crea dataframe per gli attributi dei nodi
  df <- data.frame(
    node_id = 1:netsize,
    network = net_idx,
    male = net$male,
    female = net$female,
    other = net$other,
    novice = net$novice,
    netsize = netsize
  )
  
  all_data <- rbind(all_data, df)
  cat("✓\n")
}

# Salva
output_file <- file.path(output_dir, "clubdata_nodes.csv")
write.csv(all_data, output_file, row.names = FALSE)
cat("\n✓ Salvato:", output_file, "\n")
cat("  ", nrow(all_data), "righe,", ncol(all_data), "colonne\n\n")

# Salva anche la matrice di amicizia per ogni rete (come lista separata)
cat("Estraendo matrici di amicizia...\n")
for (net_idx in seq_along(clubdata)) {
  friendship_matrix <- clubdata[[net_idx]]$friendship
  output_file <- file.path(output_dir, paste0("clubdata_friendship_net", net_idx, ".csv"))
  write.csv(friendship_matrix, output_file)
  cat("  ✓ Rete", net_idx, "salvata\n")
}

# ============================================
# 2. ELABORA CLUBDATA_RSIENA_FREQ
# ============================================
cat("\n========================================\n")
cat("2. ELABORAZIONE CLUBDATA_RSIENA_FREQ\n")
cat("========================================\n")

cat("Tipo: Oggetto S3 'siena' per l'analisi di reti\n")
cat("Elementi:", length(clubdata_rsiena_freq), "periodi\n\n")

# Estrai informazioni dalle liste siena
freq_summary <- data.frame(
  period = seq_along(clubdata_rsiena_freq),
  n_observations = sapply(clubdata_rsiena_freq, function(x) x$observations),
  n_depvars = sapply(clubdata_rsiena_freq, function(x) length(x$depvars))
)

output_file <- file.path(output_dir, "clubdata_rsiena_freq_summary.csv")
write.csv(freq_summary, output_file, row.names = FALSE)
cat("✓ Salvato:", output_file, "\n\n")

cat("Informazioni estratte:\n")
print(freq_summary)

# ============================================
# 3. ELABORA CLUBDATA_RSIENA_VOL
# ============================================
cat("\n========================================\n")
cat("3. ELABORAZIONE CLUBDATA_RSIENA_VOL\n")
cat("========================================\n")

cat("Tipo: Oggetto S3 'siena' per l'analisi di reti\n")
cat("Elementi:", length(clubdata_rsiena_vol), "periodi\n\n")

# Estrai informazioni dalle liste siena
vol_summary <- data.frame(
  period = seq_along(clubdata_rsiena_vol),
  n_observations = sapply(clubdata_rsiena_vol, function(x) x$observations),
  n_depvars = sapply(clubdata_rsiena_vol, function(x) length(x$depvars))
)

output_file <- file.path(output_dir, "clubdata_rsiena_vol_summary.csv")
write.csv(vol_summary, output_file, row.names = FALSE)
cat("✓ Salvato:", output_file, "\n\n")

cat("Informazioni estratte:\n")
print(vol_summary)

# ============================================
# RIEPILOGO
# ============================================
cat("\n========================================\n")
cat("✓ PROCESSO COMPLETATO!\n")
cat("========================================\n\n")

cat("File CSV generati:\n")
cat("  1. clubdata_nodes.csv\n")
cat("     → Attributi dei nodi per tutte le reti\n\n")
cat("  2. clubdata_friendship_net[1-5].csv\n")
cat("     → Matrici di amicizia per ogni rete\n\n")
cat("  3. clubdata_rsiena_freq_summary.csv\n")
cat("     → Riepilogo dati frequentist RSIENA\n\n")
cat("  4. clubdata_rsiena_vol_summary.csv\n")
cat("     → Riepilogo dati volume RSIENA\n\n")

cat("Tutti i file si trovano in:\n")
cat(output_dir, "\n\n")

cat("NOTE:\n")
cat("  - I dati RSIENA sono complessi (oggetti S3 specializzati)\n")
cat("  - Sono stati estratti i componenti principali\n")
cat("  - Per analisi più dettagliate, usa R direttamente con il pacchetto 'RSiena'\n")
