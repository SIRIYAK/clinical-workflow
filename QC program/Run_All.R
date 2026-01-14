## Set Working Directory
#setwd("D:/Eikon/Work/Studies/EIK1001-005")

 # path
path_QC <- "D:/Siriyak IMP Data/Desktop/EIK1001_005/QC"
#Output
# path_QC_output <- "D:/Siriyak IMP Data/Desktop/EIK1001_005/QC/QC Output"

setwd(path_QC)

source("QC Program/Read_All.R")

systime <- Sys.time()

# Create a filename with the current system time
filename <- paste0("QC_SUMMARY_REPORT_", format(systime, "%d%b%y"), ".xlsx")

# Full path for the output file
output_file <- paste0(getwd(), "/QC Output/", filename)

suppressWarnings(file.remove("QC Output/QC_SUMMARY_05Feb24.xlsx"))
wb <- createWorkbook()

source("QC Program/AESAE.R")
source("QC Program/BEBIOMRKR.R")
source("QC Program/BECTDNA.R")
source("QC Program/BEDNA.R")
source("QC Program/BERNA.R")
source("QC Program/BETTS.R")
source("QC Program/CMATM.R")
source("QC Program/CMGEN.R")
source("QC Program/DDGEN.R")
source("QC Program/DMGEN.R")
source("QC Program/DSIC.R")
source("QC Program/DSSTAT.R")
source("QC Program/ECGEN.R")
source("QC Program/EGGEN.R")
source("QC Program/IEGEN.R")
source("QC Program/ISADA.R")
source("QC Program/LBLOCAL.R")
source("QC Program/MHGEN.R")
source("QC Program/MHSDD.R")
source("QC Program/MIPDL1.R")
source("QC Program/NRATTQ.R")
source("QC Program/NRCOMMONQ.R")
source("QC Program/PCSAMPLE.R")
source("QC Program/PRATRADI.R")
source("QC Program/PRATSURG.R")
source("QC Program/PRGEN.R")
source("QC Program/PRPE.R")
source("QC Program/RSECOG.R")
source("QC Program/RSEVAL.R")
source("QC Program/SSLFU.R")
source("QC Program/SUGEN.R")
source("QC Program/SVUNSCH.R")
source("QC Program/TUTR.R")
source("QC Program/VSGEN.R")


# saveWorkbook(wb, file = "QC Output/QC_SUMMARY_05Feb24.xlsx", overwrite = TRUE)
# rm(wb)
# systime <- Sys.time()
# 
# # Create a filename with the current system time
# filename <- paste0("QC_SUMMARY_REPORT_", format(systime, "%d%b%y"), ".xlsx")
# 
# # # Save the workbook
# # saveWorkbook(wb, file = paste0(path_QC_output, filename), overwrite = TRUE)
# # Full path for the output file
# output_file <- paste0(getwd(), "/QC Output/", filename)

# Save the workbook and check for success
tryCatch({
  saveWorkbook(wb, file = output_file, overwrite = TRUE)
  message("Workbook saved successfully as ", output_file)
}, error = function(e) {
  message("Error in saving the workbook: ", e$message)
})

rm(wb)
