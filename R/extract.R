#-----------------------------------------------------------------------
source(paste0(project_path, "R/functions.R"))
login(username, password, base.url)
#--------------------------------------------------------------------

# Download FP Data
monthly_download(fp_dataset, 
                 startdate, enddate, 
                 orgunit, 
                 paste0(project_path, "raw/FP/"))
monthly_download(imm_dataset, 
                 startdate, enddate, 
                 orgunit, 
                 paste0(project_path, "raw/Immunization/"))
monthly_download(mal_dataset, 
                 startdate, enddate, 
                 orgunit, 
                 paste0(project_path, "raw/Malaria/"))
monthly_download(nut_dataset, 
                 startdate, enddate, 
                 orgunit, 
                 paste0(project_path, "raw/Nutrition/"))


# Reporting Rates
fetch_reports(fp_dataset, 
              startdate, enddate, 
              orgunit, 
              paste0(project_path, "raw/Reports/FP/"))
fetch_reports(imm_dataset, 
              startdate, enddate, 
              orgunit, 
              paste0(project_path, "raw/Reports/Immunization/"))
fetch_reports(mal_dataset, 
              startdate, enddate, 
              orgunit, 
              paste0(project_path, "raw/Reports/Malaria/"))
fetch_reports(nut_dataset, 
              startdate, enddate, 
              orgunit, 
              paste0(project_path, "raw/Reports/Nutrition/"))

