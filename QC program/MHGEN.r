rstudioapi::writeRStudioPreference("data_viewer_max_columns", 1000L)

## Get CDB Data
MHGEN_CDB <- mhgen
# Post processing for compare
MHGEN_CDB <- MHGEN_CDB %>% mutate(across(everything(), as.character))
MHGEN_CDB$DLASTMOD <- substring(MHGEN_CDB$DLASTMOD,1,16)
MHGEN_CDB <- MHGEN_CDB %>% mutate_if(is.character, ~replace_na(.,""))
MHGEN_CDB <- MHGEN_CDB[order(MHGEN_CDB$STUDYID,MHGEN_CDB$COUNTRY,MHGEN_CDB$SITENUM,MHGEN_CDB$SUBJID,MHGEN_CDB$VISITNUM,MHGEN_CDB$VISITDT,MHGEN_CDB$FORMID,as.integer(MHGEN_CDB$FORMSEQ),as.integer(MHGEN_CDB$IGSEQ)), ]

## Get EDC Data
SUBJECTS <- sys_sub

MH_GEN_01 <- mh_gen_01
MH_GEN_01 <- MH_GEN_01 %>% mutate(across(everything(), as.character))
MH_GEN_01 <- MH_GEN_01 %>% mutate_if(is.character, ~replace_na(.,""))

NR_MHQ_01 <- nr_mhq_01
NR_MHQ_01 <- NR_MHQ_01 %>% mutate(across(everything(), as.character))
NR_MHQ_01 <- NR_MHQ_01 %>% mutate_if(is.character, ~replace_na(.,""))

#-----------  FINAL union query--
MHGEN_UNION <-
  sqldf(
    " SELECT
'EIK1001-005_TST3'  'STUDYID'
 ,'EDC'  'SOURCE'
,NR_MHQ_01.COUNTRY  'COUNTRY'
,NR_MHQ_01.SITENUM  'SITENUM'
,NR_MHQ_01.SUBJID  'SUBJID'
,	 S1.STATUS 'SUBJSTATUS'
,NR_MHQ_01.EGROUPDEF  'EGID'
,NR_MHQ_01.ESEQ  'EGSEQ'
,CASE NR_MHQ_01.EGROUPDEF
   WHEN 'eg_TRTA1C' THEN NR_MHQ_01.EGROUP||' '||NR_MHQ_01.EVENT
   ELSE NR_MHQ_01.EVENT
   END AS 'VISIT'
,CASE 
WHEN NR_MHQ_01.EVENTEID= 'ev_SCREEN' THEN -28
WHEN NR_MHQ_01.EVENTEID= 'ev_ENROLL' THEN  -2
WHEN NR_MHQ_01.EVENTEID= 'ev_DAY1' THEN NR_MHQ_01.ESEQ + 0.01
WHEN NR_MHQ_01.EVENTEID= 'ev_DAY8' THEN NR_MHQ_01.ESEQ + 0.08
WHEN NR_MHQ_01.EVENTEID= 'ev_DAY15' THEN NR_MHQ_01.ESEQ + 0.15
WHEN NR_MHQ_01.EVENTEID= 'ev_TUPB' THEN 41 + NR_MHQ_01.ESEQ * 0.01
WHEN NR_MHQ_01.EVENTEID= 'ev_EOT' THEN 60
WHEN NR_MHQ_01.EVENTEID= 'ev_DSEOT' THEN 60.1
WHEN NR_MHQ_01.EVENTEID= 'ev_SFU30D' THEN 70.30
WHEN NR_MHQ_01.EVENTEID= 'ev_SFU90D' THEN 70.90
WHEN NR_MHQ_01.EVENTEID= 'ev_PTFU' THEN 75 + NR_MHQ_01.ESEQ * 0.01
WHEN NR_MHQ_01.EVENTEID= 'ev_LFU' THEN 80 + NR_MHQ_01.ESEQ * 0.01
WHEN NR_MHQ_01.EVENTEID= 'ev_DSEOS' THEN 90.1
WHEN NR_MHQ_01.EVENTEID= 'ev_LOGS' THEN 98
WHEN NR_MHQ_01.EVENTEID= 'ev_UNS' THEN 99 + NR_MHQ_01.ESEQ * 0.01
ELSE NR_MHQ_01.EVENTEID
END as 'VISITNUM'
,NR_MHQ_01.EVENTDT  'VISITDT'
, case when(MH_GEN_01.FORM is not null)
       then MH_GEN_01.FORM
	   else NR_MHQ_01.FORM end as
	   FORM
, case when(MH_GEN_01.FORMDEF is not null)
       then MH_GEN_01.FORMDEF
	   else NR_MHQ_01.FORMDEF end
	   FORMID
, case when(MH_GEN_01.FSEQ is not null)
       then MH_GEN_01.FSEQ
	   else NR_MHQ_01.FSEQ end AS
	   FORMSEQ
, case when(MH_GEN_01.FORMSTATUS is not null)
       then
       CASE MH_GEN_01.FORMSTATUS
	      WHEN 'Submitted' THEN 'submitted__v'
	      WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	      WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	      ELSE MH_GEN_01.FORMSTATUS
	     END
	     else
	     CASE NR_MHQ_01.FORMSTATUS
	      WHEN 'Submitted' THEN 'submitted__v'
	      WHEN 'In Progress Post Submit' THEN 'in_progress_post_submit__v'
	      WHEN 'In Edit' THEN 'in_progress_post_submit__v'
	      ELSE NR_MHQ_01.FORMSTATUS
	     END
	     end AS
	   FORMSTATUS
, case when(MH_GEN_01.IGSEQ is not null)
       then MH_GEN_01.IGSEQ
	   else NR_MHQ_01.IGSEQ  end
	   IGSEQ
, case when(MH_GEN_01.DLASTMOD is not null)
     then MH_GEN_01.DLASTMOD
	   else NR_MHQ_01.DLASTMOD   END as
	   DLASTMOD
	   ,MH_GEN_01.DV_MHCAT  'V_MHCAT'
	   ,MH_GEN_01.V_MHTERM  'V_MHTERM'
,MH_GEN_01.V_MHSTDAT  'V_MHSTDAT'
,MH_GEN_01.V_MHSTDAT  'X_MHSTDAT'

,MH_GEN_01.V_MHONGO  'V_MHONGO'
,MH_GEN_01.V_MHENDAT  'V_MHENDAT'
,MH_GEN_01.V_MHENDAT  'X_MHENDAT'
,NR_MHQ_01.X_MHYN  'X_MHYN'
,MH_GEN_01.CRSTATUS			'CX_CRSTATUS'
,MH_GEN_01.DICTVER		'CV_QVAL_DICTVER'
,MH_GEN_01.LLT					'CV_MHLLT'
,MH_GEN_01.LLTID				'CV_MHLLTCD'	
,MH_GEN_01.PT					 'CV_MHDECOD'
,MH_GEN_01.PTID					'CV_MHPTCD'
,MH_GEN_01.HLT					'CV_MHHLT'
,MH_GEN_01.HLTID					'CV_MHHLTCD'
,MH_GEN_01.HLGT					 'CV_MHHLGT'
,MH_GEN_01.HLGTID				'CV_MHHLGTCD'
,MH_GEN_01.SOC					'CV_MHSOC' 
,MH_GEN_01.SOCID					'CV_MHSOCCD'
,MH_GEN_01.PrimPath			'CX_PRIMPATH'
,MH_GEN_01.LastCodedBy			'CX_LASTCODEDAT'
,MH_GEN_01.LastCodEDat			'CX_LASTCODEDBY'


FROM
    NR_MHQ_01 NR_MHQ_01
    left join SUBJECTS S1
     ON S1.SUBJID=NR_MHQ_01.SUBJID
  	AND S1.SITENUM=NR_MHQ_01.SITENUM
  	left join MH_GEN_01 MH_GEN_01
     ON MH_GEN_01.SUBJID=NR_MHQ_01.SUBJID
  	AND MH_GEN_01.SITENUM=NR_MHQ_01.SITENUM
WHERE
    (NR_MHQ_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit') 
    or 
    MH_GEN_01.FORMSTATUS IN ('Submitted','In Progress Post Submit','In Edit'))
   AND (MH_GEN_01.FORMILB !='true' OR NR_MHQ_01.FORMILB !='true')
	
     "
  )

# AND (MH_GEN_01.FORMILB !='true' OR NR_MHQ_01.FORMILB !='true')
# Enhancement - New Variable
# "X_MHSTDAT
# X_MHENDAT"

# Call the function -Convert_Date_Vals
CharDate_Cols <-c("V_MHSTDAT","V_MHENDAT")
datetime_columns <- NULL #c("DLASTMOD")
table_name <- c("MHGEN_UNION")
MHGEN_EDC <- Convert_Date_Vals(MHGEN_UNION, CharDate_Cols,datetime_columns,table_name)

# Arrange columns same as CDB
MHGEN_EDC <- MHGEN_EDC[names(MHGEN_CDB)]

# Post processing for compare
MHGEN_EDC$DLASTMOD <- substring(MHGEN_EDC$DLASTMOD,1,16)
MHGEN_EDC <- MHGEN_EDC %>% mutate_if(is.character, ~replace_na(.,""))
MHGEN_EDC <- MHGEN_EDC[order(MHGEN_EDC$STUDYID,MHGEN_EDC$COUNTRY,MHGEN_EDC$SITENUM,MHGEN_EDC$SUBJID,MHGEN_EDC$VISITNUM,MHGEN_EDC$VISITDT,MHGEN_EDC$FORMID,as.integer(MHGEN_EDC$FORMSEQ),as.integer(MHGEN_EDC$IGSEQ)), ]

#Generate Compare Summary Report
MHGEN_EDC <- MHGEN_EDC %>% mutate(across(everything(), as.character))
MHGEN_CDB <- MHGEN_CDB %>% mutate(across(everything(), as.character))
MHGEN_SUMMARY <- capture.output(summary(comparedf(MHGEN_EDC, MHGEN_CDB)))
MHGEN_SUMMARY

#Export Summary Report
addWorksheet(wb, "MHGEN_SUMMARY")
writeData(wb, sheet = "MHGEN_SUMMARY", x = MHGEN_SUMMARY, headerStyle = openxlsx_getOp("headerStyle"),
          borders = openxlsx_getOp("borders", "none"),
          borderColour = openxlsx_getOp("borderColour", "black"),
          borderStyle = openxlsx_getOp("borderStyle", "thin"),
          withFilter = openxlsx_getOp("withFilter", FALSE),
          keepNA = openxlsx_getOp("keepNA", FALSE),
          na.string = openxlsx_getOp("na.string"))

#Export QC Datasets
write_xpt(MHGEN_EDC,"QC Output/Datasets/EDC/MHGEN_EDC.xpt")
write_xpt(MHGEN_CDB,"QC Output/Datasets/CDB/MHGEN_CDB.xpt")

rm(SUBJECTS)
rm(CharDate_Cols)
rm(datetime_columns)
rm(table_name)