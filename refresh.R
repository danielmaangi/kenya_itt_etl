source("~/projects/insupplyHealth/kenya_itt/data/kenya_itt/R/packages.R")
project_path <- "~/projects/insupplyHealth/kenya_itt/data/kenya_itt/"

# Specify query parameters
username <- "Maangi"
password <- "kiMaNi:1991"
base.url <- "https://hiskenya.org/"
enddate <- Sys.Date()  # End date is today
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
source(paste0(project_path, "R/load.R"))
