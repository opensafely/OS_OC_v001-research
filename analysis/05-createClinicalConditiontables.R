# ##==============================================================================
# Analysis filename:			05-createClinicalConditiontables
# Project:				OC evaluation
# Author:					MF 
# Date: 					10/05/2021
# Version: 				R 
# Description:	Prevalence of top clinical conditions among those with an eConsultation code recorded
# Output to csv files
# Datasets used:			input_v2.csv
# Datasets created: 		TBA
# Other output: tables: TBA			
# Log file: log-05-createClinicalConditiontables
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-05-createClinicalConditiontables.txt"))

flag_gtsummaryoperational = TRUE

## library
library(tidyverse)
if (flag_gtsummaryoperational){
  library(gtsummary)  
}
library(gt)
library(here)
library(webshot)
#webshot::install_phantomjs()

# create directory for saving tables, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}

## import and pre-process cohort data
df_input <- read_csv(
  here::here("output", "input_v2.csv"))

df_cleaned <- df_input %>%
  mutate(age_group = factor(cut(age,breaks = c(0,18,40,50,60,70,80, Inf),dig.lab = 2)),
         sex = factor(case_when(sex=="F" ~ "Female",sex=="M" ~ "Male",TRUE ~ "Other/Unknown")),
         ethnicity = factor(case_when(ethnicity==1 ~ "White",ethnicity==2 ~ "Mixed",ethnicity==3 ~ "Asian",ethnicity==4 ~ "Black",ethnicity==5 ~ "Other",TRUE~"Other")),
         care_home_type=factor(case_when(care_home_type=="PC" ~ "Care home",care_home_type=="PN" ~ "Care home",care_home_type=="PS" ~ "Care home",TRUE ~ "Non")),
         gp_consult_pre_had = ifelse(is.na(gp_consult_pre_count)|gp_consult_pre_count==0,0,1),
         gp_consult_post_had = ifelse(is.na(gp_consult_post_count)|gp_consult_post_count==0,0,1),
         econsult_pre_had = ifelse(is.na(econsult_pre_count)|econsult_pre_count==0,0,1),
         econsult_post_had = ifelse(is.na(econsult_post_count)|econsult_post_count==0,0,1),
         livingalone = ifelse(hh_size<=1,1,0),
         imd_quin=ifelse(is.na(imd)|imd=="U",NA,imd),
         rural_urban=factor(case_when(rural_urban %in% c(1,2,3,4)~"Urban",rural_urban %in% c(5,6,7,8)~"Rural",TRUE~"Other"))
  )


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


if (flag_gtsummaryoperational){
  
  ## Characteristics of those with any OC consultation in the post period (pandemic), only for practices with any eConsultation coding recorded in that period
  study_pop_post <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_post_had,na.rm=T)!=0) %>% ungroup() %>%
                      select(c(starts_with("history"),"econsult_pre_had","econsult_post_had"))
  
  (gt_econsult_pop_post <- study_pop_post %>%
      tbl_summary(by=econsult_post_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar20-Feb21**"))
  
  ## Characteristics of those with any OC consultation in the post period (pandemic), only for practices with any eConsultation coding recorded in that period
  study_pop_pre <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_pre_had,na.rm=T)!=0) %>% ungroup() %>%
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had"))
  
  (gt_econsult_pop_pre <- study_pop_pre %>%
      tbl_summary(by=econsult_pre_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar19-Feb20**"))
  
  # Use function from gt package to save table as neat html
  gt::gtsave(as_gt(gt_econsult_pop_pre), file = file.path(here::here("output","tables"), "gt_econsult_pop_pre.html"))
  gt::gtsave(as_gt(gt_econsult_pop_post), file = file.path(here::here("output","tables"), "gt_econsult_pop_post.html"))
  
  # Change contextual/cohort: rather than being for all patients in practices with eConsultation code, focus further only on patients with either GP_consult or eConsult code
  ## Characteristics of those with any OC consultation in the post period (pandemic), only for practices with any eConsultation coding recorded in that period. Compare those with either GPconsult or eConsult in that period
  study_consultpop_post <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_post_had,na.rm=T)!=0) %>% ungroup() %>%
    filter(econsult_post_had>0|gp_consult_post_had>0) %>%
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_post_had"))
  
  (gt_econsult_consultpop_post <- study_consultpop_post %>%
      tbl_summary(by=econsult_post_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)#**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar20-Feb21 (among those with an eConsult/GP consultation)**"))
  
  ## Characteristics of those with any OC consultation in the pre period (pre-pandemic), only for practices with any eConsultation coding recorded in that period. Compare those with either GPconsult or eConsult in that period
  study_consultpop_pre <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_pre_had,na.rm=T)!=0) %>% ungroup() %>%
    filter(econsult_pre_had>0|gp_consult_pre_had>0) %>%
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_pre_had"))
  
  (gt_econsult_consultpop_pre <- study_consultpop_pre %>%
      tbl_summary(by=econsult_pre_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)#**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar19-Feb20 (among those with an eConsult/GP consultation)**"))
  
  # Use function from gt package to save table as neat html
  gt::gtsave(as_gt(gt_econsult_consultpop_pre), file = file.path(here::here("output","tables"), "gt_econsult_consultpop_pre.html"))
  gt::gtsave(as_gt(gt_econsult_consultpop_post), file = file.path(here::here("output","tables"), "gt_econsult_consultpop_post.html"))
  
}  

## close log connection
sink()


