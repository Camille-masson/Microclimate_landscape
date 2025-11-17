## CONFIGURATION DU PROJET ###


#Installed.Package
if (!require("renv")) install.packages("renv")
library(renv)
deps <- renv::dependencies()
packages <- unique(deps$Package)

installed_pkgs <- installed.packages()[, "Package"]
missing_pkgs <- setdiff(packages, installed_pkgs)

if (length(missing_pkgs) > 0) {
  install.packages(missing_pkgs, dependencies = TRUE, repos = "https://cran.rstudio.com/")
}

#sapply(packages, require, character.only = TRUE)





# Définition des chemins 
root_dir <- getwd()  # Récupère le chemin du projet automatiquement
inputs_dir <- file.path(root_dir, "inputs")
data_dir <- file.path(inputs_dir, "sheeps")
output_dir <- file.path(root_dir, "outputs")
functions_dir <- file.path(root_dir, "functions")

if (! dir.exists(inputs_dir)) dir.create(inputs_dir)
if (! dir.exists(data_dir)) dir.create(data_dir)
if (! dir.exists(output_dir)) dir.create(output_dir)
if (! dir.exists(functions_dir)) dir.create(functions_dir)