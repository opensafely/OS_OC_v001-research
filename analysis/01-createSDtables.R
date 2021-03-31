# ##==============================================================================
# Analysis filename:			01-createSDtables
# Project:				OC evaluation
# Author:					MF 
# Date: 					16/12/2020
# Version: 				R 
# Description:	Produce descriptives of GP consultation and OC consultation
# Output to csv files
# Datasets used:			input_ori.csv
# Datasets created: 		None
# Other output: tables: 'tb*.csv'			
# Log file: log-01-createSDtables
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-01-createSDtables.txt"))

flag_gtsummaryoperational = TRUE

## library
library(tidyverse)
if (flag_gtsummaryoperational){
  library(gtsummary)  
}
library(gt)
library(here)
#library(webshot)
#webshot::install_phantomjs()

# create directory for saving tables, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}

## import and pre-process cohort data
df_input <- read_csv(
  here::here("output", "input_ori.csv"))

df_cleaned <- df_input %>%
  mutate(age_group = factor(cut(age,breaks = c(0,18,40,50,60,70,80, Inf),dig.lab = 2)),
         sex = factor(case_when(sex=="F" ~ "Female",sex=="M" ~ "Male",TRUE ~ "Other/Unknown")),
         ethnicity = factor(case_when(ethnicity==1 ~ "White",ethnicity==2 ~ "Mixed",ethnicity==3 ~ "Asian",ethnicity==4 ~ "Black",ethnicity==5 ~ "Other",TRUE~"Other")),
         care_home_type=factor(case_when(care_home_type=="PC" ~ "Care home",care_home_type=="PN" ~ "Care home",care_home_type=="PS" ~ "Care home",TRUE ~ "Non")),
         gp_consult_had = ifelse(is.na(gp_consult_count)|gp_consult_count==0,0,1),
         oc_instance_had = ifelse(is.na(OC_instance)|OC_instance==0,0,1),
         livingalone = ifelse(hh_size<=1,1,0),
         has_disability = ifelse(is.na(has_disability),0,has_disability),
         imd_quin=ifelse(is.na(imd)|imd==0,NA_integer_,imd),
         rural_urban=factor(case_when(rural_urban %in% c(1,2,3,4)~"Urban",rural_urban %in% c(5,6,7,8)~"Rural",TRUE~"Other"))
         
  )


if (flag_gtsummaryoperational){
  ## Characteristics of those with any OC consultation, any GP consultation and overall population
  desc_vars=c("sex","age","age_group","ethnicity","livingalone","region","imd_quin","rural_urban","care_home_type","oc_instance_had")
  (gt_ocpop <- df_cleaned %>% select(desc_vars) %>% tbl_summary(by=oc_instance_had) %>% add_p() %>% add_overall() %>% modify_header(label="**Characteristic | had OC**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had any OC instance**"))
  
  desc_vars2=c("sex","age","age_group","ethnicity","livingalone","region","imd_quin","rural_urban","care_home_type","gp_consult_had")
  (gt_gpcpop <- df_cleaned %>% select(desc_vars2) %>% tbl_summary(by=gp_consult_had) %>% add_p() %>% add_overall() %>% modify_header(label="**Characteristic | had GP consultation**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had any GP consultation**"))
  
  # Use function from gt package to save table as neat png
  #gt::gtsave(as_gt(gt_ocpop), file = file.path(here::here("output","tables"), "gt_ocpop.png"))
  #gt::gtsave(as_gt(gt_gpcpop), file = file.path(here::here("output","tables"), "gt_gpcpop.png"))
  
  # steps to remove input data and strip further where possible
  gt_gpcpop$inputs <- NULL
  gt_gpcpop$call_list <- NULL
  gt_gpcpop$meta_data <- NULL
  gt_ocpop$inputs <- NULL
  gt_ocpop$call_list <- NULL
  gt_ocpop$meta_data <- NULL
  
  # Save dta with actual table data, but underlying data removed
  save(gt_ocpop,file = file.path(here::here("output","tables"), "gt_ocpop.RData")) 
  save(gt_gpcpop,file = file.path(here::here("output","tables"), "gt_gpcpop.RData"))
  
  # Save unformatted for disclosiveness assessment
  aux<-as.data.frame(gt_ocpop$table_body)
  write.csv(aux,paste0(here::here("output","tables"),"/gt_ocpop_unformatted.csv"))
  aux<-as.data.frame(gt_gpcpop$table_body)
  write.csv(aux,paste0(here::here("output","tables"),"/gt_gpcpop_unformatted.csv"))
}


## Redactor code (W.Hulme)
redactor <- function(n, threshold){
  # given a vector of frequencies, this returns a boolean vector that is TRUE if
  # a) the frequency is <= the redaction threshold and
  # b) if the sum of redacted frequencies in a) is still <= the threshold, then the
  # next largest frequency is also redacted
  n <- as.integer(n)
  leq_threshold <- dplyr::between(n, 1, threshold)
  n_sum <- sum(n)
  # redact if n is less than or equal to redaction threshold
  redact <- leq_threshold
  # also redact next smallest n if sum of redacted n is still less than or equal to threshold
  if((sum(n*leq_threshold) <= threshold) & any(leq_threshold)){
    redact[which.min(dplyr::if_else(leq_threshold, n_sum+1L, n))] = TRUE
  }
  n_redacted <- if_else(redact, NA_integer_, n)
}


## Rates per characteristic
df_to_tbrates <- function(mydf,myvars,flag_save=0,tb_name="latest",n_redact=6) {
  mytb=
    mydf %>%
    group_by_at(myvars) %>%
    summarise(
      population=n(),
      gp_consult=sum(gp_consult_count,na.rm=T),
      gp_consult_covg = sum(gp_consult_had,na.rm=T),
      oc_instance=sum(OC_instance,na.rm=T),
      oc_instance_covg=sum(oc_instance_had,na.rm=T),
    ) %>%
    mutate(
      gp_consult=redactor(gp_consult,n_redact),
      gp_consult_covg = redactor(gp_consult_covg,n_redact),
      oc_instance=redactor(oc_instance,n_redact),
      oc_instance_covg=redactor(oc_instance_covg,n_redact),
      gp_consult_rate=gp_consult/population,
      gp_consult_covg_rate=gp_consult_covg/population,
      oc_instance_rate=oc_instance/population,
      oc_instance_covg_rate=oc_instance_covg/population
    )
  if (flag_save){
    write.csv(mytb,paste0(here::here("output","tables"),"/",tb_name,".csv"))
  }
  return(mytb)
}


## OC and GP rates per STP
tb02_gpcr_stp <- df_to_tbrates(df_cleaned,c("stp"),1,"tb02_gpcr_stp")

### OC and GP rates per practice
#tb03_gpcr_practice <- df_to_tbrates(df_cleaned,c("practice"),1,"tb03_gpcr_practice")


## OC and GP rates per age and gender
tb04_gpcr_agesex <- df_to_tbrates(df_cleaned,c("age_group","sex"),1,"tb04_gpcr_agesex")

## OC and GP rates by ethnicity
tb05_gpcr_ethnicity <- df_to_tbrates(df_cleaned,c("ethnicity"),1,"tb05_gpcr_ethnicity")

## OC and GP rates by region and rurality
tb06_gpcr_ruc <- df_to_tbrates(df_cleaned,c("region","rural_urban"),1,"tb06_gpcr_ruc")

## OC and GP rates by care home status
tb07_gpcr_care <- df_to_tbrates(df_cleaned,c("care_home_type"),1,"tb07_gpcr_care")

## OC and GP rates by presence of disability
tb08_gpcr_dis <- df_to_tbrates(df_cleaned,c("has_disability"),1,"tb08_gpcr_dis")

## OC and GP rates by presence of disability
tb09_gpcr_imd <- df_to_tbrates(df_cleaned,c("imd_quin"),1,"tb09_gpcr_imd")

## close log connection
sink()


