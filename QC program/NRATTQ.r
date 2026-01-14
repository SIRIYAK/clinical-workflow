rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
NRATTQ_CDB <- nrattq
# Post processing for compare
NRATTQ_CDB <- NRATTQ_CDB %>% mutate(across(everything(), as.character))
NRATTQ_CDB$DLASTMOD <- substring(NRATTQ_CDB$DLASTMOD,1,16)
NRATTQ_CDB <- NRATTQ_CDB %>% mutate_if(is.character, ~replace_na(.,""))
NRATTQ_CDB <- NRATTQ_CDB[order(NRATTQ_CDB$STUDYID,NRATTQ_CDB$COUNTRY,NRATTQ_CDB$SITENUM,NRATTQ_CDB$SUBJID,NRATTQ_CDB$VISITDT,NRATTQ_CDB$FORMID,as.integer(NRATTQ_CDB$FORMSEQ),as.integer(NRATTQ_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub

NR_ATTQ_01 <- nr_attq_01
NR_ATTQ_01 <- NR_ATTQ_01 %>% mutate(across(everything(), as.character))
NR_ATTQ_01 <- NR_ATTQ_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
NRATTQ_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,NR_ATTQ_01.COUNTRY  'COUNTRY'
,NR_ATTQ_01.SITENUM  'SITENUM'
,NR_ATTQ_01.SUBJID  'SUBJID'
,S1.STATUS 'SUBJSTATUS'

,NR_ATTQ_01.EGROUPDEF  'EGID'
,NR_ATTQ_01.ESEQ  'EGSEQ'
,CASE NR_ATTQ_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN NR_ATTQ_01.EGROUP||' '||NR_ATTQ_01.EVENT
   ELSE NR_ATTQ_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN NR_ATTQ_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN NR_ATTQ_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN NR_ATTQ_01.EVENTEID= 'ev_DAY1' THEN NR_ATTQ_01.ESEQ + 0.01
WHEN NR_ATTQ_01.EVENTEID= 'ev_DAY8' THEN NR_ATTQ_01.ESEQ + 0.08
WHEN NR_ATTQ_01.EVENTEID= 'ev_DAY15' THEN NR_ATTQ_01.ESEQ + 0.15
WHEN NR_ATTQ_01.EVENTEID= 'ev_TUPB' THEN 41 + NR_ATTQ_01.ESEQ * 0.01
WHEN NR_ATTQ_01.EVENTEID= 'ev_EOT' THEN 60
WHEN NR_ATTQ_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN NR_ATTQ_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN NR_ATTQ_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN NR_ATTQ_01.EVENTEID= 'ev_PTFU' THEN 75 + NR_ATTQ_01.ESEQ * 0.01
WHEN NR_ATTQ_01.EVENTEID= 'ev_LFU' THEN 80 + NR_ATTQ_01.ESEQ * 0.01
WHEN NR_ATTQ_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN NR_ATTQ_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN NR_ATTQ_01.EVENTEID= 'ev_UNS' THEN 99 + NR_ATTQ_01.ESEQ * 0.01
ELSE NR_ATTQ_01.EVENTEID
END as 'VISITNUM'
,NR_ATTQ_01.EVENTDT  'VISITDT'
,NR_ATTQ_01.FORM  'FORM'
,NR_ATTQ_01.FORMDEF  'FORMID'
,NR_ATTQ_01.FSEQ  'FORMSEQ'
,CASE NR_ATTQ_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  NR_ATTQ_01.FORMSTATUS
	    END AS 'FORMSTATUS'
,NR_ATTQ_01.IGSEQ  'IGSEQ'
,NR_ATTQ_01.DLASTMOD  'DLASTMOD'
,NR_ATTQ_01.X_PATMYN  'X_PATMYN'
,NR_ATTQ_01.X_PATRADIYN  'X_PATRADIYN'
,NR_ATTQ_01.X_PATSURGYN  'X_PATSURGYN'
FROM
              NR_ATTQ_01 NR_ATTQ_01,
              SUBJECTS S1

              WHERE
              S1.SUBJID=NR_ATTQ_01.SUBJID
              AND S1.SITENUM=NR_ATTQ_01.SITENUM
              AND NR_ATTQ_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
AND NR_ATTQ_01.FORMILB !='true'
    
 "
  )

# AND NR_ATTQ_01.FORMILB !='true'

# Call the function -Convert_Date_Vals 
CharDate_Cols <-c()
datetime_columns <- NULL #c("DLASTMOD")
table_name <- c("NRATTQ_UNION")
NRATTQ_EDC <- Convert_Date_Vals(NRATTQ_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
NRATTQ_EDC <- NRATTQ_EDC[names(NRATTQ_UNION)]

# Post processing for compare
NRATTQ_EDC$DLASTMOD <- substring(NRATTQ_EDC$DLASTMOD,1,16)
NRATTQ_EDC <- NRATTQ_EDC %>% mutate_if(is.character, ~replace_na(.,""))
NRATTQ_EDC <- NRATTQ_EDC[order(NRATTQ_EDC$STUDYID,NRATTQ_EDC$COUNTRY,NRATTQ_EDC$SITENUM,NRATTQ_EDC$SUBJID,NRATTQ_EDC$VISITDT,NRATTQ_EDC$FORMID,as.integer(NRATTQ_EDC$FORMSEQ),as.integer(NRATTQ_EDC$IGSEQ)), ]

#Generate Compare Summary Report
NRATTQ_EDC <- NRATTQ_EDC %>% mutate(across(everything(), as.character))
NRATTQ_CDB <- NRATTQ_CDB %>% mutate(across(everything(), as.character))
NRATTQ_SUMMARY <- capture.output(summary(comparedf(NRATTQ_EDC, NRATTQ_CDB)))
print(NRATTQ_SUMMARY)

#Export Summary Report
addWorksheet(wb, "NRATTQ_SUMMARY")
writeData(wb, sheet = "NRATTQ_SUMMARY", x = NRATTQ_SUMMARY)

#Export QC Datasets
write_xpt(NRATTQ_EDC,"QC Output/Datasets/EDC/NRATTQ_EDC.xpt")
write_xpt(NRATTQ_CDB,"QC Output/Datasets/CDB/NRATTQ_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)