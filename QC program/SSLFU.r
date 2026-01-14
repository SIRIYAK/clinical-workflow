rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
SSLFU_CDB <- sslfu
# Post processing for compare
SSLFU_CDB <- SSLFU_CDB %>% mutate(across(everything(), as.character))
SSLFU_CDB$DLASTMOD <- substring(SSLFU_CDB$DLASTMOD,1,16)
SSLFU_CDB <- SSLFU_CDB %>% mutate_if(is.character, ~replace_na(.,""))
SSLFU_CDB <- SSLFU_CDB[order(SSLFU_CDB$STUDYID,SSLFU_CDB$COUNTRY,SSLFU_CDB$SITENUM,SSLFU_CDB$SUBJID,SSLFU_CDB$VISITDT,SSLFU_CDB$FORMID,as.integer(SSLFU_CDB$FORMSEQ),as.integer(SSLFU_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub
SS_LFU_01 <- ss_lfu_01
SS_LFU_01 <- SS_LFU_01 %>% mutate(across(everything(), as.character))
SS_LFU_01 <- SS_LFU_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
SSLFU_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,SS_LFU_01.COUNTRY  'COUNTRY'
,SS_LFU_01.SITENUM  'SITENUM'
,SS_LFU_01.SUBJID  'SUBJID'
,	 S1.STATUS 'SUBJSTATUS'

,SS_LFU_01.EGROUPDEF  'EGID'
,SS_LFU_01.ESEQ  'EGSEQ'
,CASE SS_LFU_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN SS_LFU_01.EGROUP||' '||SS_LFU_01.EVENT
   ELSE SS_LFU_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN SS_LFU_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN SS_LFU_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN SS_LFU_01.EVENTEID= 'ev_DAY1' THEN SS_LFU_01.ESEQ + 0.01
WHEN SS_LFU_01.EVENTEID= 'ev_DAY8' THEN SS_LFU_01.ESEQ + 0.08
WHEN SS_LFU_01.EVENTEID= 'ev_DAY15' THEN SS_LFU_01.ESEQ + 0.15
WHEN SS_LFU_01.EVENTEID= 'ev_TUPB' THEN 41 + SS_LFU_01.ESEQ * 0.01
WHEN SS_LFU_01.EVENTEID= 'ev_EOT' THEN 60
WHEN SS_LFU_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN SS_LFU_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN SS_LFU_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN SS_LFU_01.EVENTEID= 'ev_PTFU' THEN 75 + SS_LFU_01.ESEQ * 0.01
WHEN SS_LFU_01.EVENTEID= 'ev_LFU' THEN 80 + SS_LFU_01.ESEQ * 0.01
WHEN SS_LFU_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN SS_LFU_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN SS_LFU_01.EVENTEID= 'ev_UNS' THEN 99 + SS_LFU_01.ESEQ * 0.01
ELSE SS_LFU_01.EVENTEID
END as 'VISITNUM'
,SS_LFU_01.EVENTDT  'V_SSDAT'
,SS_LFU_01.EVENTDT  'X_SSDAT'
,SS_LFU_01.EVENTDT  'VISITDT'
,SS_LFU_01.FORM  'FORM'
,SS_LFU_01.FORMDEF  'FORMID'
,SS_LFU_01.FSEQ  'FORMSEQ'
,CASE SS_LFU_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  SS_LFU_01.FORMSTATUS
	   END AS 'FORMSTATUS'
,SS_LFU_01.IGSEQ  'IGSEQ'
,SS_LFU_01.DLASTMOD  'DLASTMOD'
,SS_LFU_01.V_QVAL_SSCNTMOD   'V_QVAL_SSCNTMOD'
,SS_LFU_01.V_QVAL_CNTMODOT  'V_QVAL_CNTMODOT'
,SS_LFU_01.V_SSORRES_SURVSTAT  'V_SSORRES_SURVSTAT'
,SS_LFU_01.V_QVAL_LKNSSDAT  'V_QVAL_LKNSSDAT'
,SS_LFU_01.V_QVAL_LKNSSDAT  'X_QVAL_LKNSSDAT'

  FROM
              SS_LFU_01 SS_LFU_01,
              SUBJECTS S1
              WHERE
              S1.SUBJID=SS_LFU_01.SUBJID
              AND S1.SITENUM=SS_LFU_01.SITENUM
              AND SS_LFU_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
               AND SS_LFU_01.FORMILB !='true'
    
"
)

# AND SS_LFU_01.FORMILB !='true'
# Call the function -Convert_Date_Vals
CharDate_Cols <-c("V_SSDAT")
datetime_columns <- NULL #c("DLASTMOD")
table_name <- c("SSLFU_UNION")
SSLFU_EDC <- Convert_Date_Vals(SSLFU_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
SSLFU_EDC <- SSLFU_EDC[names(SSLFU_CDB)]

# Post processing for compare
SSLFU_EDC$DLASTMOD <- substring(SSLFU_EDC$DLASTMOD,1,16)
SSLFU_EDC <- SSLFU_EDC %>% mutate_if(is.character, ~replace_na(.,""))
SSLFU_EDC <- SSLFU_EDC[order(SSLFU_EDC$STUDYID,SSLFU_EDC$COUNTRY,SSLFU_EDC$SITENUM,SSLFU_EDC$SUBJID,SSLFU_EDC$VISITDT,SSLFU_EDC$FORMID,as.integer(SSLFU_EDC$FORMSEQ),as.integer(SSLFU_EDC$IGSEQ)), ]

#Generate Compare Summary Report
SSLFU_EDC <- SSLFU_EDC %>% mutate(across(everything(), as.character))
SSLFU_CDB <- SSLFU_CDB %>% mutate(across(everything(), as.character))
SSLFU_SUMMARY <- capture.output(summary(comparedf(SSLFU_EDC, SSLFU_CDB)))
print(SSLFU_SUMMARY)

#Export Summary Report
addWorksheet(wb, "SSLFU_SUMMARY")
writeData(wb, sheet = "SSLFU_SUMMARY", x = SSLFU_SUMMARY)

#Export QC Datasets
write_xpt(SSLFU_EDC,"QC Output/Datasets/EDC/SSLFU_EDC.xpt")
write_xpt(SSLFU_CDB,"QC Output/Datasets/CDB/SSLFU_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)