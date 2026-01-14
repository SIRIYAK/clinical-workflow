rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
DSIC_CDB <- dsic
# Post processing for compare
DSIC_CDB <- DSIC_CDB %>% mutate(across(everything(), as.character))
DSIC_CDB$DLASTMOD <- substring(DSIC_CDB$DLASTMOD,1,16)
DSIC_CDB <- DSIC_CDB %>% mutate_if(is.character, ~replace_na(.,""))
DSIC_CDB <- DSIC_CDB[order(DSIC_CDB$STUDYID,DSIC_CDB$COUNTRY,DSIC_CDB$SITENUM,DSIC_CDB$SUBJID,DSIC_CDB$VISITDT,DSIC_CDB$FORMID,as.integer(DSIC_CDB$FORMSEQ),as.integer(DSIC_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub

DS_IC_01 <- ds_ic_01
DS_IC_01 <- DS_IC_01 %>% mutate(across(everything(), as.character))
DS_IC_01 <- DS_IC_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
DSIC_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,DS_IC_01.COUNTRY  'COUNTRY'
,DS_IC_01.SITENUM  'SITENUM'
,DS_IC_01.SUBJID  'SUBJID'
,	 S1.STATUS 'SUBJSTATUS'
,DS_IC_01.EGROUPDEF  'EGID'
,DS_IC_01.ESEQ  'EGSEQ'
,CASE DS_IC_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN DS_IC_01.EGROUP||' '||DS_IC_01.EVENT
   ELSE DS_IC_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN DS_IC_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN DS_IC_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN DS_IC_01.EVENTEID= 'ev_DAY1' THEN DS_IC_01.ESEQ + 0.01
WHEN DS_IC_01.EVENTEID= 'ev_DAY8' THEN DS_IC_01.ESEQ + 0.08
WHEN DS_IC_01.EVENTEID= 'ev_DAY15' THEN DS_IC_01.ESEQ + 0.15
WHEN DS_IC_01.EVENTEID= 'ev_TUPB' THEN 41 + DS_IC_01.ESEQ * 0.01
WHEN DS_IC_01.EVENTEID= 'ev_EOT' THEN 60
WHEN DS_IC_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN DS_IC_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN DS_IC_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN DS_IC_01.EVENTEID= 'ev_PTFU' THEN 75 + DS_IC_01.ESEQ * 0.01
WHEN DS_IC_01.EVENTEID= 'ev_LFU' THEN 80 + DS_IC_01.ESEQ * 0.01
WHEN DS_IC_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN DS_IC_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN DS_IC_01.EVENTEID= 'ev_UNS' THEN 99 + DS_IC_01.ESEQ * 0.01
ELSE DS_IC_01.EVENTEID
END as 'VISITNUM'
,DS_IC_01.EVENTDT  'VISITDT'
,DS_IC_01.FORM  'FORM'
,DS_IC_01.FORMDEF  'FORMID'
,DS_IC_01.FSEQ  'FORMSEQ'
,CASE DS_IC_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  DS_IC_01.FORMSTATUS
	   END AS 'FORMSTATUS'
,DS_IC_01.IGSEQ  'IGSEQ'
,DS_IC_01.DLASTMOD  'DLASTMOD'
,DS_IC_01.V_DSSTDAT_ICFDT  'V_DSSTDAT_ICFDT'
,DS_IC_01.V_DSSTDAT_ICFDT  'X_DSSTDAT_ICFDT'
,DS_IC_01.V_QVAL_PROTVER  'V_QVAL_PROTVER'

FROM
              DS_IC_01 DS_IC_01,
              SUBJECTS S1

              WHERE
              S1.SUBJID=DS_IC_01.SUBJID
              AND  S1.SITENUM=DS_IC_01.SITENUM
              AND DS_IC_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
AND DS_IC_01.FORMILB !='true'
   
              "
  )


# AND DS_IC_01.FORMILB !='true'
# "X_DSSTDAT_ICFDT
# X_DSSTDAT_BIOPSYW"


# Call the function -Convert_Date_Vals 
CharDate_Cols <-c("V_DSSTDAT_ICFDT")
datetime_columns <- NULL
table_name <- c("DSIC_UNION")
DSIC_EDC <- Convert_Date_Vals(DSIC_UNION, CharDate_Cols,datetime_columns,table_name)

#arrange columns as same as CDB
DSIC_EDC <- DSIC_EDC[names(DSIC_CDB)]

# Post processing for compare
DSIC_EDC$DLASTMOD <- substring(DSIC_EDC$DLASTMOD,1,16)
DSIC_EDC <- DSIC_EDC %>% mutate_if(is.character, ~replace_na(.,""))
DSIC_EDC <- DSIC_EDC[order(DSIC_EDC$STUDYID,DSIC_EDC$COUNTRY,DSIC_EDC$SITENUM,DSIC_EDC$SUBJID,DSIC_EDC$VISITDT,DSIC_EDC$FORMID,as.integer(DSIC_EDC$FORMSEQ),as.integer(DSIC_EDC$IGSEQ)), ]

#Generate Compare Summary Report
DSIC_EDC <- DSIC_EDC %>% mutate(across(everything(), as.character))
DSIC_CDB <- DSIC_CDB %>% mutate(across(everything(), as.character))
DSIC_SUMMARY <- capture.output(summary(comparedf(DSIC_EDC, DSIC_CDB)))
DSIC_SUMMARY

#Export Summary Report
addWorksheet(wb, "DSIC_SUMMARY")
writeData(wb, sheet = "DSIC_SUMMARY", x = DSIC_SUMMARY)

#Export QC Datasets
write_xpt(DSIC_EDC,"QC Output/Datasets/EDC/DSIC_EDC.xpt")
write_xpt(DSIC_CDB,"QC Output/Datasets/CDB/DSIC_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)