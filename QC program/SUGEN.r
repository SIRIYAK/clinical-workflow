rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
SUGEN_CDB <- sugen
# Post processing for compare
SUGEN_CDB <- SUGEN_CDB %>% mutate(across(everything(), as.character))
SUGEN_CDB$DLASTMOD <- substring(SUGEN_CDB$DLASTMOD,1,16)
SUGEN_CDB <- SUGEN_CDB %>% mutate_if(is.character, ~replace_na(.,""))
SUGEN_CDB <- SUGEN_CDB[order(SUGEN_CDB$STUDYID,SUGEN_CDB$COUNTRY,SUGEN_CDB$SITENUM,SUGEN_CDB$SUBJID,SUGEN_CDB$VISITDT,SUGEN_CDB$FORMID,as.integer(SUGEN_CDB$FORMSEQ),as.integer(SUGEN_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub
SU_GEN_01 <- su_gen_01
SU_GEN_01 <- SU_GEN_01 %>% mutate(across(everything(), as.character))
SU_GEN_01 <- SU_GEN_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
SUGEN_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,SU_GEN_01.COUNTRY  'COUNTRY'
,SU_GEN_01.SITENUM  'SITENUM'
,SU_GEN_01.SUBJID  'SUBJID'
,	S1.STATUS 'SUBJSTATUS'
,SU_GEN_01.EGROUPDEF  'EGID'
,SU_GEN_01.ESEQ  'EGSEQ'
,CASE SU_GEN_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN SU_GEN_01.EGROUP||' '||SU_GEN_01.EVENT
   ELSE SU_GEN_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN SU_GEN_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN SU_GEN_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN SU_GEN_01.EVENTEID= 'ev_DAY1' THEN SU_GEN_01.ESEQ + 0.01
WHEN SU_GEN_01.EVENTEID= 'ev_DAY8' THEN SU_GEN_01.ESEQ + 0.08
WHEN SU_GEN_01.EVENTEID= 'ev_DAY15' THEN SU_GEN_01.ESEQ + 0.15
WHEN SU_GEN_01.EVENTEID= 'ev_TUPB' THEN 41 + SU_GEN_01.ESEQ * 0.01
WHEN SU_GEN_01.EVENTEID= 'ev_EOT' THEN 60
WHEN SU_GEN_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN SU_GEN_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN SU_GEN_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN SU_GEN_01.EVENTEID= 'ev_PTFU' THEN 75 + SU_GEN_01.ESEQ * 0.01
WHEN SU_GEN_01.EVENTEID= 'ev_LFU' THEN 80 + SU_GEN_01.ESEQ * 0.01
WHEN SU_GEN_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN SU_GEN_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN SU_GEN_01.EVENTEID= 'ev_UNS' THEN 99 + SU_GEN_01.ESEQ * 0.01
ELSE SU_GEN_01.EVENTEID
END as 'VISITNUM'
,SU_GEN_01.EVENTDT  'VISITDT'
,SU_GEN_01.FORM  'FORM'
,SU_GEN_01.FORMDEF  'FORMID'
,SU_GEN_01.FSEQ  'FORMSEQ'
,CASE SU_GEN_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  SU_GEN_01.FORMSTATUS
	   END AS 'FORMSTATUS'
,SU_GEN_01.IGSEQ  'IGSEQ'
,SU_GEN_01.DLASTMOD  'DLASTMOD'
,SU_GEN_01.DV_SUCAT  'V_SUCAT'
,SU_GEN_01.V_SUSTENRF  'V_SUSTENRF'
FROM
              SU_GEN_01 SU_GEN_01,
              SUBJECTS S1
              WHERE
              S1.SUBJID=SU_GEN_01.SUBJID
              AND S1.SITENUM=SU_GEN_01.SITENUM
              AND SU_GEN_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
                 AND SU_GEN_01.FORMILB !='true'
    
"
)

# AND SU_GEN_01.FORMILB !='true'

# Call the function -Convert_Date_Vals
CharDate_Cols <-c()
datetime_columns <- NULL #c("DLASTMOD")
table_name <- c("SUGEN_UNION")
SUGEN_EDC <- Convert_Date_Vals(SUGEN_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
SUGEN_EDC <- SUGEN_EDC[names(SUGEN_CDB)]

# Post processing for compare
SUGEN_EDC$DLASTMOD <- substring(SUGEN_EDC$DLASTMOD,1,16)
SUGEN_EDC <- SUGEN_EDC %>% mutate_if(is.character, ~replace_na(.,""))
SUGEN_EDC <- SUGEN_EDC[order(SUGEN_EDC$STUDYID,SUGEN_EDC$COUNTRY,SUGEN_EDC$SITENUM,SUGEN_EDC$SUBJID,SUGEN_EDC$VISITDT,SUGEN_EDC$FORMID,as.integer(SUGEN_EDC$FORMSEQ),as.integer(SUGEN_EDC$IGSEQ)), ]

#Generate Compare Summary Report
SUGEN_EDC <- SUGEN_EDC %>% mutate(across(everything(), as.character))
SUGEN_CDB <- SUGEN_CDB %>% mutate(across(everything(), as.character))
SUGEN_SUMMARY <- capture.output(summary(comparedf(SUGEN_EDC, SUGEN_CDB)))
print(SUGEN_SUMMARY)

#Export Summary Report
addWorksheet(wb, "SUGEN_SUMMARY")
writeData(wb, sheet = "SUGEN_SUMMARY", x = SUGEN_SUMMARY)

#Export QC Datasets
write_xpt(SUGEN_EDC,"QC Output/Datasets/EDC/SUGEN_EDC.xpt")
write_xpt(SUGEN_CDB,"QC Output/Datasets/CDB/SUGEN_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)