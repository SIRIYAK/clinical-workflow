rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
IEGEN_CDB <- iegen
# Post processing for compare
IEGEN_CDB <- IEGEN_CDB %>% mutate(across(everything(), as.character))
IEGEN_CDB$DLASTMOD <- substring(IEGEN_CDB$DLASTMOD,1,16)
IEGEN_CDB <- IEGEN_CDB %>% mutate_if(is.character, ~replace_na(.,""))
IEGEN_CDB <- IEGEN_CDB[order(IEGEN_CDB$STUDYID,IEGEN_CDB$COUNTRY,IEGEN_CDB$SITENUM,IEGEN_CDB$SUBJID,IEGEN_CDB$VISITDT,IEGEN_CDB$FORMID,as.integer(IEGEN_CDB$FORMSEQ),as.integer(IEGEN_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub

IE_GEN_01 <- ie_gen_01
IE_GEN_01 <- IE_GEN_01 %>% mutate(across(everything(), as.character))
IE_GEN_01 <- IE_GEN_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
IEGEN_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,IE_GEN_01.COUNTRY  'COUNTRY'
,IE_GEN_01.SITENUM  'SITENUM'
,IE_GEN_01.SUBJID  'SUBJID'
,S1.STATUS  'SUBJSTATUS'
,IE_GEN_01.EGROUPDEF  'EGID'
,IE_GEN_01.ESEQ  'EGSEQ'
,CASE IE_GEN_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN IE_GEN_01.EGROUP||' '||IE_GEN_01.EVENT
   ELSE IE_GEN_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN IE_GEN_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN IE_GEN_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN IE_GEN_01.EVENTEID= 'ev_DAY1' THEN IE_GEN_01.ESEQ + 0.01
WHEN IE_GEN_01.EVENTEID= 'ev_DAY8' THEN IE_GEN_01.ESEQ + 0.08
WHEN IE_GEN_01.EVENTEID= 'ev_DAY15' THEN IE_GEN_01.ESEQ + 0.15
WHEN IE_GEN_01.EVENTEID= 'ev_TUPB' THEN 41 + IE_GEN_01.ESEQ * 0.01
WHEN IE_GEN_01.EVENTEID= 'ev_EOT' THEN 60
WHEN IE_GEN_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN IE_GEN_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN IE_GEN_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN IE_GEN_01.EVENTEID= 'ev_PTFU' THEN 75 + IE_GEN_01.ESEQ * 0.01
WHEN IE_GEN_01.EVENTEID= 'ev_LFU' THEN 80 + IE_GEN_01.ESEQ * 0.01
WHEN IE_GEN_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN IE_GEN_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN IE_GEN_01.EVENTEID= 'ev_UNS' THEN 99 + IE_GEN_01.ESEQ * 0.01
ELSE IE_GEN_01.EVENTEID
END as 'VISITNUM'
,IE_GEN_01.EVENTDT  'VISITDT'
,IE_GEN_01.FORM  'FORM'
,IE_GEN_01.FORMDEF  'FORMID'
,IE_GEN_01.FSEQ  'FORMSEQ'
,CASE IE_GEN_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  IE_GEN_01.FORMSTATUS
	   END AS 'FORMSTATUS'
,IE_GEN_01.IGSEQ  'IGSEQ'
,IE_GEN_01.DLASTMOD  'DLASTMOD'
,IE_GEN_01.X_IEYN  'X_IEYN'
,IE_GEN_01.V_IECAT  'V_IECAT'
,IE_GEN_01.V_IETESTCD_INCL  'V_IETESTCD_INCL'
,IE_GEN_01.V_IETESTCD_EXCL  'V_IETESTCD_EXCL'
FROM
              IE_GEN_01 IE_GEN_01,
              SUBJECTS S1
              WHERE
              S1.SUBJID=IE_GEN_01.SUBJID
              AND S1.SITENUM=IE_GEN_01.SITENUM
              AND IE_GEN_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
               AND IE_GEN_01.FORMILB !='true'
    
   "
  )

# AND IE_GEN_01.FORMILB !='true'

# Call the function -Convert_Date_Vals 
CharDate_Cols <-c()
datetime_columns <- NULL #c("DLASTMOD")
table_name <- c("IEGEN_UNION")
IEGEN_EDC <- Convert_Date_Vals(IEGEN_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
IEGEN_EDC <- IEGEN_EDC[names(IEGEN_CDB)]

# Post processing for compare
IEGEN_EDC$DLASTMOD <- substring(IEGEN_EDC$DLASTMOD,1,16)
IEGEN_EDC <- IEGEN_EDC %>% mutate_if(is.character, ~replace_na(.,""))
IEGEN_EDC <- IEGEN_EDC[order(IEGEN_EDC$STUDYID,IEGEN_EDC$COUNTRY,IEGEN_EDC$SITENUM,IEGEN_EDC$SUBJID,IEGEN_EDC$VISITDT,IEGEN_EDC$FORMID,as.integer(IEGEN_EDC$FORMSEQ),as.integer(IEGEN_EDC$IGSEQ)), ]

#Generate Compare Summary Report
IEGEN_EDC <- IEGEN_EDC %>% mutate(across(everything(), as.character))
IEGEN_CDB <- IEGEN_CDB %>% mutate(across(everything(), as.character))
IEGEN_SUMMARY <- capture.output(summary(comparedf(IEGEN_EDC, IEGEN_CDB)))
IEGEN_SUMMARY

#Export Summary Report
addWorksheet(wb, "IEGEN_SUMMARY")
writeData(wb, sheet = "IEGEN_SUMMARY", x = IEGEN_SUMMARY)

#Export QC Datasets
write_xpt(IEGEN_EDC,"QC Output/Datasets/EDC/IEGEN_EDC.xpt")
write_xpt(IEGEN_CDB,"QC Output/Datasets/CDB/IEGEN_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)