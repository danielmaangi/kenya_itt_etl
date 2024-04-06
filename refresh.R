project_path <- "~/projects/insupplyHealth/kenya_itt/data/kenya_itt/"

# Set the custom library path
custom_lib_path <- paste0(project_path, "renv/library/R-4.3/x86_64-pc-linux-gnu")

# Set the library paths
.libPaths(c(custom_lib_path, .libPaths()))

source("~/projects/insupplyHealth/kenya_itt/data/kenya_itt/R/packages.R")

# Specify query parameters
username <- "Maangi"
password <- "kiMaNi:1991"
base.url <- "https://hiskenya.org/"
enddate <- Sys.Date()-months(1)  # End date is today
startdate <- enddate - months(12)  # Start date is 12 months ago
orgunit <- "HfVjCurKxh2"

# datasets
fp_dataset <- "g3RQRuh8ikd" # Facility Contraceptives Consumption Report and Request Form
imm_dataset <- "XoHnrLBL1qB" # MOH 710 Vaccines and Immunisation Rev 2020
mal_dataset <- "RRnz4uPHXdl" # MOH 743 Malaria Commodities Form Rev 2020
nut_dataset <- "mVRzpvT29MP" # MOH 734 F-CDRR for Nutrition Commodities Revision 2019

source(paste0(project_path, "R/extract.R"))
source(paste0(project_path, "R/metadata.R"))
source(paste0(project_path, "R/transform-reports.R"))
source(paste0(project_path, "R/transform-fp.R"))
source(paste0(project_path, "R/load-reports.R"))
source(paste0(project_path, "R/load_program_data.R"))
