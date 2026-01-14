rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
DDGEN_CDB <- ddgen
# Post processing for compare
DDGEN_CDB <- DDGEN_CDB %>% mutate(across(everything(), as.character))
DDGEN_CDB$DLASTMOD <- substring(DDGEN_CDB$DLASTMOD,1,16)
DDGEN_CDB <- DDGEN_CDB %>% mutate_if(is.character, ~replace_na(.,""))
DDGEN_CDB <- DDGEN_CDB[order(DDGEN_CDB$STUDYID,DDGEN_CDB$COUNTRY,DDGEN_CDB$SITENUM,DDGEN_CDB$SUBJID,DDGEN_CDB$VISITNUM,DDGEN_CDB$VISITDT,DDGEN_CDB$FORMID,as.integer(DDGEN_CDB$FORMSEQ),as.integer(DDGEN_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub

DD_GEN_01 <- dd_gen_01
DD_GEN_01 <- DD_GEN_01 %>% mutate(across(everything(), as.character))
DD_GEN_01 <- DD_GEN_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
DDGEN_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
,'EDC'  'SOURCE'
,DD_GEN_01.COUNTRY  'COUNTRY'
,DD_GEN_01.SITENUM  'SITENUM'
,DD_GEN_01.SUBJID  'SUBJID'
 ,	S1.STATUS 'SUBJSTATUS'
,DD_GEN_01.EGROUPDEF  'EGID'
,DD_GEN_01.ESEQ  'EGSEQ'
,CASE DD_GEN_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN DD_GEN_01.EGROUP||' '||DD_GEN_01.EVENT
   ELSE DD_GEN_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN DD_GEN_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN DD_GEN_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN DD_GEN_01.EVENTEID= 'ev_DAY1' THEN DD_GEN_01.ESEQ + 0.01
WHEN DD_GEN_01.EVENTEID= 'ev_DAY8' THEN DD_GEN_01.ESEQ + 0.08
WHEN DD_GEN_01.EVENTEID= 'ev_DAY15' THEN DD_GEN_01.ESEQ + 0.15
WHEN DD_GEN_01.EVENTEID= 'ev_TUPB' THEN 41 + DD_GEN_01.ESEQ * 0.01
WHEN DD_GEN_01.EVENTEID= 'ev_EOT' THEN 60
WHEN DD_GEN_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN DD_GEN_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN DD_GEN_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN DD_GEN_01.EVENTEID= 'ev_PTFU' THEN 75 + DD_GEN_01.ESEQ * 0.01
WHEN DD_GEN_01.EVENTEID= 'ev_LFU' THEN 80 + DD_GEN_01.ESEQ * 0.01
WHEN DD_GEN_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN DD_GEN_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN DD_GEN_01.EVENTEID= 'ev_UNS' THEN 99 + DD_GEN_01.ESEQ * 0.01
ELSE DD_GEN_01.EVENTEID
END as 'VISITNUM'
,DD_GEN_01.EVENTDT  'VISITDT'
,DD_GEN_01.FORM  'FORM'
,DD_GEN_01.FORMDEF  'FORMID'
,DD_GEN_01.FSEQ  'FORMSEQ'
,CASE DD_GEN_01.FORMSTATUS
	   WHEN 'Submitted' THEN 'submitted__v'
	   WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	   WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	   ELSE  DD_GEN_01.FORMSTATUS
	   END AS 'FORMSTATUS'
,DD_GEN_01.IGSEQ  'IGSEQ'
,DD_GEN_01.DLASTMOD  'DLASTMOD'

,DD_GEN_01.EVENTDT  'V_DDDAT'
,DD_GEN_01.EVENTDT  'X_DDDAT'
,DD_GEN_01.V_DTHDAT  'V_DTHDAT'

,DD_GEN_01.V_DTHDAT  'X_DTHDAT'
,DD_GEN_01.V_DDORRES_PRCDTH  'V_DDORRES_PRCDTH'
,DD_GEN_01.V_QVAL_PRCDTHOT  'V_QVAL_PRCDTHOT'
,DD_GEN_01.V_DDORRES_AUTOPIND  'V_DDORRES_AUTOPIND'
,DD_GEN_01.FL_IDVARVAL_DDAE_DEF  'FL_IDVARVAL_DDAE'

FROM
              DD_GEN_01 DD_GEN_01,
              SUBJECTS S1

              WHERE
              S1.SUBJID=DD_GEN_01.SUBJID
              AND  S1.SITENUM=DD_GEN_01.SITENUM
              AND DD_GEN_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit')
   

   "
  )

# AND DD_GEN_01.FORMILB !='true'

# Call the function -Convert_Date_Vals 
CharDate_Cols <-c("V_DTHDAT","V_DDDAT")
datetime_columns <- NULL #c()
table_name <- c("DDGEN_UNION")
DDGEN_EDC <- Convert_Date_Vals(DDGEN_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
DDGEN_EDC <- DDGEN_EDC[names(DDGEN_CDB)]

# Post processing for compare
DDGEN_EDC$DLASTMOD <- substring(DDGEN_EDC$DLASTMOD,1,16)
DDGEN_EDC <- DDGEN_EDC %>% mutate_if(is.character, ~replace_na(.,""))
DDGEN_EDC <- DDGEN_EDC[order(DDGEN_EDC$STUDYID,DDGEN_EDC$COUNTRY,DDGEN_EDC$SITENUM,DDGEN_EDC$SUBJID,DDGEN_EDC$VISITNUM,DDGEN_EDC$VISITDT,DDGEN_EDC$FORMID,as.integer(DDGEN_EDC$FORMSEQ),as.integer(DDGEN_EDC$IGSEQ)), ]

#Generate Compare Summary Report
DDGEN_EDC <- DDGEN_EDC %>% mutate(across(everything(), as.character))
DDGEN_CDB <- DDGEN_CDB %>% mutate(across(everything(), as.character))
DDGEN_SUMMARY <- capture.output(summary(comparedf(DDGEN_EDC, DDGEN_CDB)))
DDGEN_SUMMARY

#Export Summary Report
addWorksheet(wb, "DDGEN_SUMMARY")
writeData(wb, sheet = "DDGEN_SUMMARY", x = DDGEN_SUMMARY)

#Export QC Datasets
write_xpt(DDGEN_EDC,"QC Output/Datasets/EDC/DDGEN_EDC.xpt")
write_xpt(DDGEN_CDB,"QC Output/Datasets/CDB/DDGEN_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)