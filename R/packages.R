# SETUP
# Load the renv package
#install.packages("renv")

.libPaths(c("~/projects/insupplyHealth/kenya_itt/data/kenya_itt/renv/library", .libPaths()))

# Required Libraries
library(httr)
library(rjson)
library(tidyverse)
library(lubridate)
library(data.table)
library(readxl)
library(jsonlite)
library(datimutils)


# devtools::install_github(repo = "https://github.com/pepfar-datim/datimutils.git", 
#                          ref = "master")
