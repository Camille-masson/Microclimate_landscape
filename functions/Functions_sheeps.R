# Lit un .Rdata dans un environnement temporaire
load_rdata <- function(file) {
  e    <- new.env()
  objs <- load(file, envir = e)
  
  # garder uniquement les data.frames
  cand <- Filter(function(nm) is.data.frame(e[[nm]]), objs)
  if (!length(cand)) return(NULL)
  
  df <- e[[ cand[1] ]]
  
  # Métadonnées
  df$source_file <- basename(file)
  df$collar_id   <- tools::file_path_sans_ext(basename(file))
  
  # Renommer les colonnes 7, 8, 11 -> lat, lon, Altitude
  colnames(df)[c(7, 8, 11)] <- c("lat", "lon", "Altitude")
  
  # Date
  df$date <- as.POSIXct(df$date, tz = "GMT", format = "%Y-%m-%d %H:%M:%S")
  
  # Numérique
  df$lat      <- as.numeric(df$lat)
  df$lon      <- as.numeric(df$lon)
  df$Altitude <- as.numeric(df$Altitude)
  
  # Colonnes gardées
  cols_keep <- c("lat", "lon", "Altitude", "x", "y", "date",
                 "infoloc", "temp", "id_gps", "collar_id")
  cols_keep <- cols_keep[cols_keep %in% names(df)]
  df <- df[, cols_keep, drop = FALSE]
  
  return(df)
}




