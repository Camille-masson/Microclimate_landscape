#### 0. LIBRARIES AND CONSTANTS ####
#----------------------------------#
gc()

## Loading configuration ##
source("config.R")

## Definition of the analysis year and the alpine pastures to process ##
YEAR = 2019
alpage = "Sept-Laux"
alpages = "Sept-Laux"
TYPE <- "other" #Type of input data : catlog (at 2 minute) or other (catlog/other)

ALPAGES_TOTAL <- list(
  "9999" = c("Alpage_demo"),
  "2013" = c("Combe-Madame"),
  "2014" = c("Combe-Madame"),
  "2015" = c("Combe-Madame"),
  "2016" = c("Combe-Madame"),
  "2017" = c("Combe-Madame"),
  "2018" = c("Ane-et-Buyant", "Bedina", "Pesee", "Sept-Laux"),
  "2019" = c("Ane-et-Buyant", "Bedina", "Pesee", "Sept-Laux"),
  "2020" = c("Ane-et-Buyant", "Bedina", "Pesee","Rieuxclaret", "Sept-Laux"),
  "2021" = c("Ane-et-Buyant", "Bedina", "Pesee","Combe-Madame", "Sept-Laux"),
  "2022" = c("Ane-et-Buyant", "Bedina", "Combe-Madame", "Grande-Fesse", "Jas-des-Lievres", "Pesee","Sept-Laux"),
  "2023" = c("Ane-et-Buyant", "Bedina", "Cayolle", "Crouzet", "Combe", "Combe-Madame", "Grande-Cabane", "Lanchatra", "Pesee", "Rouanette", "Sanguiniere", "Sept-Laux", "Vacherie-de-Roubion", "Viso"),
  "2024" = c("Viso", "Cayolle", "Sanguiniere"),
  "2025" = c("Viso", "Cayolle", "Sanguiniere", "Ponsonniere")
)
ALPAGES <- ALPAGES_TOTAL[[as.character(YEAR)]]





#### 0.Definition of the sampling period ##
#-----------------------------------------#
if (TRUE){
  
  ## DESCRIPTION ----
  # Définis le sampling period de chaque collier
  # et l'enregistre dans un .rds et un pdf
  
  ## LIBRARY ----
  source(file.path(functions_dir, "Functions_sheeps.R"))
  library(dplyr)
  
  ## INPUT ----
  # A folder containing the raw trajectories
  raw_data_dir <- file.path(data_dir, paste0("Colliers_", YEAR, "_brutes"))
  
  ## OUTPUT ----
  # Creation of the subfolder to store the sampling periods
  filter_output_dir <- file.path(output_dir, "0. Sampling_Periods")
  if (!dir.exists(filter_output_dir)) {
    dir.create(filter_output_dir, recursive = TRUE)
  }
  
  ## CODE ----
  sampling_periods <- identify_sampling_period(data_dir, YEAR, TYPE, alpages, output_dir)
  
  print(sampling_periods)
  
}


#### 1. Lecture données moutons ####
#----------------------------------#
if (TRUE) {  
  ## DESCRIPTION ----
  # Lecture des .Rdata de par année et par alpage et merge de l'ensemble 
  # des colliers de l'alpage avec en sortie un .RDS
  
  ## LIBRARY ----
  library(dplyr)
  library(lubridate)
  library(tools)
  source(file.path(functions_dir, "Functions_sheeps.R"))
 
  ## INPUT ----
  # A folder containing the raw trajectories in CSV format from Catlog collars, organized into subfolders named after their alpine pastures
  raw_data_dir <- file.path(data_dir, paste0("Colliers_", YEAR, "_brutes"))
  
  ## OUTPUT ----
  # Creation of the subfolder to store the sampling periods
  collar_temp_output_dir <- file.path(output_dir, "1. Collars_temperature")
  if (!dir.exists(collar_temp_output_dir)) {
    dir.create(collar_temp_output_dir, recursive = TRUE)
  }
  output_data_file <- file.path(collar_temp_output_dir, paste0("Collars_temperature_",YEAR,"_",alpage,".rds"))
  
  ## CODE ----
  # Liste les files des colliers de l'alpage
  collar_dir   <- file.path(raw_data_dir, alpage)
  file_pattern <- if (TYPE == "catlog") "\\.csv$" else "\\.Rdata$"
  read_fun     <- if (TYPE == "catlog") load_catlog_data else load_other_data_rdata
  collar_files <- list.files(collar_dir, pattern = file_pattern, full.names = TRUE)
  if (!length(collar_files)) { warning("Aucun fichier ", file_pattern, " pour ", alpage); next }
  
  # Lecture des Rdata puis merge des différents colliers
  dfs <- lapply(collar_files, load_rdata)
  dfs <- Filter(Negate(is.null), dfs)
  merged_df <- dplyr::bind_rows(dfs)
  
  # Sauvegrade du dataframe
  saveRDS(merged_df,output_data_file )
}


#### 2. Ajout des température S2M ####
#------------------------------------#
if (TRUE) {
  ## DESCRIPTION ----
  # A chaque localisation de mouton on associe la température du model S2M
  # qui se décline avec une température par heure et par jour 
  # enregistre en rds 
  
  ## LIBRARY ----
  library(terra)
  
  
  ## INPUT ----
  # Sheeps data
  sheep_data_file <- file.path(collar_temp_output_dir, paste0("Collars_temperature_",YEAR,"_",alpage,".rds"))
  
  # Temp S2M
  temp_case <- file.path(inputs_dir, "temp")
  if (!dir.exists(temp_case)) {
    dir.create(temp_case, recursive = TRUE)
  }
  s2m_case <- file.path(temp_case, "S2M")
  if (!dir.exists(s2m_case)) {
    dir.create(s2m_case, recursive = TRUE)
  }
  
  ## OUPUT ----
  # Creation of the subfolder to store the sampling periods
  collar_temp_S2M_output_dir <- file.path(output_dir, "2. Collars_temperature_S2M")
  if (!dir.exists(collar_temp_S2M_output_dir)) {
    dir.create(collar_temp_S2M_output_dir, recursive = TRUE)
  }
  output_data_file <- file.path(collar_temp_S2M_output_dir, paste0("Collars_temperature_S2M_",YEAR,"_",alpage,".rds"))
  
  
  ## CODE ----
  
  # 1. Lire le RDS des moutons
  sheep_df <- readRDS(sheep_data_file)
  
  # 2. S'assurer que la colonne date est bien en POSIXct
  if (!inherits(sheep_df$date, "POSIXt")) {
    sheep_df$date <- as.POSIXct(sheep_df$date, tz = "UTC")
  }
  
  # 3. Créer jour (YYYYMMDD) et heure (HH)
  sheep_df$day  <- format(sheep_df$date, "%Y%m%d")
  sheep_df$hour <- format(sheep_df$date, "%H")
  
  # 4. Initialiser la colonne température S2M
  sheep_df$temp_S2M <- NA_real_
  
  # 5. Boucle sur les jours présents dans les données
  jours <- unique(sheep_df$day)
  
  for (d in jours) {
    
    tif_file <- file.path(s2m_case, paste0("BELLEDONNE_TMP_5M_", d, ".tif"))
    if (!file.exists(tif_file)) {
      warning("Fichier S2M manquant : ", tif_file)
      next
    }
    
    r <- terra::rast(tif_file)           # stack 24 bandes
    noms_couches <- names(r)             # "YYYYMMDD00", "YYYYMMDD01", ...
    
    # indices des lignes de ce jour
    idx_day <- which(sheep_df$day == d)
    heures_jour <- unique(sheep_df$hour[idx_day])
    
    # boucle sur les heures de ce jour
    for (h in heures_jour) {
      
      layer_name <- paste0(d, h)         # ex : 2019070204
      
      if (!(layer_name %in% noms_couches)) {
        warning("Couche ", layer_name, " absente dans ", tif_file)
        next
      }
      
      lyr <- r[[layer_name]]
      
      # lignes de ce jour ET de cette heure
      idx <- which(sheep_df$day == d & sheep_df$hour == h)
      
      # coordonnées des points (on utilise x / y du raster S2M)
      coords <- cbind(sheep_df$x[idx], sheep_df$y[idx])
      
      ext  <- terra::extract(lyr, coords)
      vals <- ext[, 1]   # il n'y a qu'une seule colonne, la valeur raster
      
      sheep_df$temp_S2M[idx] <- vals
    }
  }
  
  # 6. Nettoyage des colonnes temporaires
  sheep_df$day  <- NULL
  sheep_df$hour <- NULL
  
  # 7. Sauvegarde en RDS
  saveRDS(sheep_df, output_data_file)
  
  
}


#### 3. Anomaly insolation ####
#----------------------------#

if (TRUE) {
  ## DESCRIPTION ----
  # A chaque localisation de mouton on associe l'anomalie d'insolation
  # qui se décline avec une anomalie par heure et par jour.
  # Les rasters sont des .tif avec 1 fichier par jour et 1 bande par heure.
  
  ## LIBRARY ----
  library(terra)
  
  
  ## INPUT ----
  # Sheeps data (avec déjà temp_S2M)
  collar_temp_S2M_input_dir <- file.path(output_dir, "2. Collars_temperature_S2M")
  sheep_data_file <- file.path(
    collar_temp_S2M_input_dir,
    paste0("Collars_temperature_S2M_", YEAR, "_", alpage, ".rds")
  )
  
  # Thermal refuge / anomalies
  thermal_case <- file.path(inputs_dir, "thermal_refuge")
  if (!dir.exists(thermal_case)) {
    dir.create(thermal_case, recursive = TRUE)
  }
  
  ## OUPUT ----
  collar_thermal_output_dir <- file.path(output_dir, "3. Collars_thermal_refuge")
  if (!dir.exists(collar_thermal_output_dir)) {
    dir.create(collar_thermal_output_dir, recursive = TRUE)
  }
  output_data_file <- file.path(
    collar_thermal_output_dir,
    paste0("Collars_thermal_refuge_", YEAR, "_", alpage, ".rds")
  )
  
  
  ## CODE ----
  
  # 1. Lire le RDS des moutons (avec temp S2M)
  sheep_df <- readRDS(sheep_data_file)
  
  # 2. S'assurer que la colonne date est bien en POSIXct
  if (!inherits(sheep_df$date, "POSIXt")) {
    sheep_df$date <- as.POSIXct(sheep_df$date, tz = "UTC")
  }
  
  # 3. Créer jour (YYYYMMDD) et heure (HH)
  sheep_df$day  <- format(sheep_df$date, "%Y%m%d")
  sheep_df$hour <- format(sheep_df$date, "%H")
  
  # 4. Initialiser la colonne d'anomalie (thermal refuge)
  sheep_df$anom_thermal_refuge <- NA_real_
  
  # 5. Boucle sur les jours présents dans les données
  jours <- unique(sheep_df$day)
  
  for (d in jours) {
    
    # Exemple de nom de fichier :
    # "BELLEDONNE_ANOMINS_25M_20190821.tif"
    tif_file <- file.path(
      thermal_case,
      paste0("BELLEDONNE_ANOMINS_25M_", d, ".tif")
    )
    
    if (!file.exists(tif_file)) {
      warning("Fichier thermal_refuge manquant : ", tif_file)
      next
    }
    
    r <- terra::rast(tif_file)   # stack avec les heures du jour
    noms_couches <- names(r)     # ex : "201908210600", "201908210700", ...
    
    # indices des lignes de ce jour
    idx_day <- which(sheep_df$day == d)
    heures_jour <- unique(sheep_df$hour[idx_day])
    
    # 6. Boucle sur les heures de ce jour
    for (h in heures_jour) {
      
      # Les bandes sont nommées YYYYMMDDHHMM -> on ajoute "00" pour les minutes
      layer_name <- paste0(d, h, "00")
      
      if (!(layer_name %in% noms_couches)) {
        warning("Couche ", layer_name, " absente dans ", tif_file)
        next
      }
      
      lyr <- r[[layer_name]]
      
      # lignes de ce jour ET de cette heure
      idx <- which(sheep_df$day == d & sheep_df$hour == h)
      
      # coordonnées des points (doivent être dans le même système que le raster)
      coords <- cbind(sheep_df$x[idx], sheep_df$y[idx])
      
      ext  <- terra::extract(lyr, coords)
      vals <- ext[, 1]   # une seule colonne : la valeur d'anomalie
      
      sheep_df$anom_thermal_refuge[idx] <- vals
    }
  }
  
  # 7. Nettoyage des colonnes temporaires
  sheep_df$day  <- NULL
  sheep_df$hour <- NULL
  
  # 8. Sauvegarde en RDS
  saveRDS(sheep_df, output_data_file)
}






















