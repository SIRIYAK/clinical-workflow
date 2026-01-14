

# clear env
rm(list=ls())



## Initiate Required Libraries
library(Hmisc)
library(haven)
library(sqldf)
library(arsenal)
library(lubridate)
library(RSQLite)
library(tcltk2)
library(stringr)
library(dplyr)
library(writexl)
library(tidyr)
library(readr)
library(do)
library(foreign)
library(openxlsx)
library(tidyverse)
library(purrr)

rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

# Set the base path (commented out)
# base_path <- "C:/Users/shethp/OneDrive - EikonTX/Documents/Work/Studies/EIK1001-005/"

# Set the sub-paths
path_edc <- "D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/EDC/EIK1001-005_EDC_05Feb24/sas"
path_cdb <- "D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/CDB/EIK1001-005_CDB_05Feb24/sas"

# Set Working Directory (commented out)
# setwd("D:/Eikon/Work/Studies/EIK1001-005")
# setwd("C:/Users/shethp/OneDrive - EikonTX/Documents/Work/Studies/EIK1001-005/CDB")

# Source Convert_Date_Vals.R script
source("D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/QC Program/date_time_split.R")
source("D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/QC Program/Convert_Date_Vals.R")

# Function to read and assign datasets
read_and_assign_datasets <- function(path) {
  files <- list.files(
    path = path,
    full.names = TRUE,
    recursive = TRUE,
    pattern = "*.sas7bdat"
  )
  names <- strsplit(files, "[/.]")
  
  for (i in seq_along(files)) {
    fileName <- files[[i]]
    dataName <- names[[i]][[length(names[[i]]) - 1]]
    tempData <- read_sas(fileName, NULL)
    assign(dataName, tempData, envir = .GlobalEnv)
  }
}

# Read CDB Datasets
read_and_assign_datasets(path_cdb)
# Read EDC Datasets
read_and_assign_datasets(path_edc)

# read CSv -Lblocal 


LBCONV_SITOUS <- read.csv("D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/CDB/EIK1001-005_CDB_05Feb24/LBCONV_SITOUS.csv")

# Define the function
convert_and_round <- function(LBLOCAL_EDC, LBCONV_SITOUS) {
  # Filter the data based on the specified conditions
  # LBLOCAL_EDC <- LBLOCAL_EDC %>%
  #   filter(Status %in% c("submitted__v", "in_progress_post_submit__v")) %>%
  #   filter(ILB == FALSE) %>%
  #   filter(!is.na(V_LBTEST_MIURIN))
  # 
  # Perform the left join with LBCONV_SITOUS
  LBLOCAL_EDC <- LBLOCAL_EDC %>%
    left_join(LBCONV_SITOUS, by = c("DX_LBCAT", "DX_LBSCAT", "V_LBTESTCD"))
  
  # Convert V_LBSTRESN, V_LBORNRLO, V_LBORNRHI, V_LBSTNRLO_OVRD, V_LBSTNRHI_OVRD, and X_CONVFACT_US to numeric
  LBLOCAL_EDC$V_LBSTRESN <- as.numeric(as.character(LBLOCAL_EDC$V_LBSTRESN))
  LBLOCAL_EDC$V_LBORNRLO <- as.numeric(as.character(LBLOCAL_EDC$V_LBORNRLO))
  LBLOCAL_EDC$V_LBORNRHI <- as.numeric(as.character(LBLOCAL_EDC$V_LBORNRHI))
  LBLOCAL_EDC$V_LBSTNRLO_OVRD <- as.numeric(as.character(LBLOCAL_EDC$V_LBSTNRLO_OVRD))
  LBLOCAL_EDC$V_LBSTNRHI_OVRD <- as.numeric(as.character(LBLOCAL_EDC$V_LBSTNRHI_OVRD))
  LBLOCAL_EDC$X_CONVFACT_US <- as.numeric(as.character(LBLOCAL_EDC$X_CONVFACT_US))
  
  # Check for NA values
  if (sum(is.na(LBLOCAL_EDC$V_LBSTRESN)) > 0) {
    warning("There are NA values in V_LBSTRESN. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(V_LBSTRESN))
  }
  
  if (sum(is.na(LBLOCAL_EDC$V_LBORNRLO)) > 0) {
    warning("There are NA values in V_LBORNRLO. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(V_LBORNRLO))
  }
  
  if (sum(is.na(LBLOCAL_EDC$V_LBORNRHI)) > 0) {
    warning("There are NA values in V_LBORNRHI. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(V_LBORNRHI))
  }
  
  if (sum(is.na(LBLOCAL_EDC$V_LBSTNRLO_OVRD)) > 0) {
    warning("There are NA values in V_LBSTNRLO_OVRD. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(V_LBSTNRLO_OVRD))
  }
  
  if (sum(is.na(LBLOCAL_EDC$V_LBSTNRHI_OVRD)) > 0) {
    warning("There are NA values in V_LBSTNRHI_OVRD. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(V_LBSTNRHI_OVRD))
  }
  
  if (sum(is.na(LBLOCAL_EDC$X_CONVFACT_US)) > 0) {
    warning("There are NA values in X_CONVFACT_US. Removing rows with NA values.")
    LBLOCAL_EDC <- LBLOCAL_EDC %>%
      filter(!is.na(X_CONVFACT_US))
  }
  
  # Perform the conversions and rounding
  LBLOCAL_EDC$V_LBSTRESC_US <- as.character(round(LBLOCAL_EDC$V_LBSTRESN * LBLOCAL_EDC$X_CONVFACT_US, 2))
  LBLOCAL_EDC$V_LBSTRESN_US <- round(LBLOCAL_EDC$V_LBSTRESN * LBLOCAL_EDC$X_CONVFACT_US, 2)
  LBLOCAL_EDC$V_LBSTRESU_US <- LBLOCAL_EDC$V_LBSTRESU_US
  
  LBLOCAL_EDC$V_LBSTNRLO_US <- round(LBLOCAL_EDC$V_LBORNRLO * LBLOCAL_EDC$X_CONVFACT_US, 2)
  LBLOCAL_EDC$V_LBSTNRHI_US <- round(LBLOCAL_EDC$V_LBORNRHI * LBLOCAL_EDC$X_CONVFACT_US, 2)
  LBLOCAL_EDC$X_LBSTNRLOHIU_US <- LBLOCAL_EDC$V_LBSTRESU_US
  
  LBLOCAL_EDC$V_LBSTNRLO_OVRD_US <- round(LBLOCAL_EDC$V_LBSTNRLO_OVRD * LBLOCAL_EDC$X_CONVFACT_US, 2)
  LBLOCAL_EDC$V_LBSTNRHI_OVRD_US <- round(LBLOCAL_EDC$V_LBSTNRHI_OVRD * LBLOCAL_EDC$X_CONVFACT_US, 2)
  LBLOCAL_EDC$X_LBSTNRLOHIU_OVRD_US <- LBLOCAL_EDC$V_LBSTRESU_US
  
  # Order the data by the specified columns
  LBLOCAL_EDC <- LBLOCAL_EDC %>%
    arrange(STUDYID, COUNTRY, SITENUM, SUBJID, VISITNUM, VISITDT, FORMID, FORMSEQ, DX_LBSCAT, IGSEQ)
  
  # Return the modified data frame
  return(LBLOCAL_EDC)
}
# commented 70 to 111 on aaug8
# # Clean up the environment
# # rm(list = c("files", "names", "i", "fileName", "dataName", "tempData"))
# 
# 
# 
# # Use ful function
# 
# 
# # Function to extract date and time components from a date-time string
# date_time_split <- function(date_string) {
#   # Extract the date and time components
#   date_part <- sub("T.*", "", date_string)
#   time_part <- sub(".*T", "", date_string)
#   time_part <- sub("-.*", "", time_part)
#   
#   # Combine the date and time components
#   # date_string <- paste(date_part, time_part)
#   date_string <- as.POSIXct(paste(date_part, time_part),
#                             format = "%Y-%m-%d %H:%M",
#                             tz="")
#   
#   strftime(date_string) 
#   # Return the result
#   return(date_string)
# }
# 
# # Function to extract date and time components from a date-time string
# date_ <- function(date_string_) {
#   
#   # Extract the date part
#   date_part_ <- as.Date(date_string_)
#   # Combine the date and time components
#   # date_string <- paste(date_part, time_part)
#   # date_string_ <- as.POSIXct(date_part_,
#   #                           format = "%Y-%m-%d",
#   #                           tz="")
#   
#   strftime(date_part_) 
#   # Return the result
#   return(date_string_)
# }
# 



