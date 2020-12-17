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
# Other output: 			
# Log file: 
# 
## ==============================================================================

## open log connection to file
#sink(here::here("logs", "log-01-createSDtables.txt"))

## library
library('tidyverse')
library(here)

## import cohort data
df_input <- read_csv(
  here::here("output", "input_ori.csv"))

df_cleaned <- df_input %>%
  mutate(age_group = cut(age,breaks = c(0,18,40,50,60,70,80, Inf),dig.lab = 2),
         sex = case_when(sex=="F" ~ "Female",sex=="M" ~ "Male",TRUE ~ sex),
         ethnicity = case_when(ethnicity==1 ~ "White",ethnicity==2 ~ "Mixed",ethnicity==3 ~ "Asian",ethnicity==4 ~ "Black",ethnicity==5 ~ "Other"),
         gp_consult_had = ifelse(is.na(gp_consult_count)|gp_consult_count==0,0,1),
         oc_instance_had = ifelse(is.na(mock_OC)|mock_OC==0,0,1)
  )


df_to_tbrates <- function(mydf,myvars,flag_save=0,tb_name="latest") {
  mytb=
    mydf %>%
    group_by_at(myvars) %>%
    summarise(
      population=n(),
      gp_consult=sum(gp_consult_count,na.rm=T),
      gp_consult_covg = sum(gp_consult_had,na.rm=T),
      gp_consult_rate=gp_consult/population,
      gp_consult_covg_rate=gp_consult_covg/population,
      oc_instance=sum(mock_OC,na.rm=T),
      oc_instance_covg=sum(oc_instance_had,na.rm=T),
      oc_instance_rate=oc_instance/population,
      oc_instance_covg_rate=oc_instance_covg/population
    )
  if (flag_save){
    write.csv(mytb,paste0(here::here("output"),"/",tb_name,".csv"))
  }
  return(mytb)
}

## OC and GP rates per region
tb01_gpcr_region <- df_to_tbrates(df_cleaned,c("region"),1,"tb01_gpcr_region")


## OC and GP rates per STP
tb02_gpcr_stp <- df_to_tbrates(df_cleaned,c("stp"),1,"tb02_gpcr_stp")

## OC and GP rates per practice
tb03_gpcr_practice <- df_to_tbrates(df_cleaned,c("practice"),1,"tb03_gpcr_practice")


## OC and GP rates per age and gender
tb04_gpcr_agesex <- df_to_tbrates(df_cleaned,c("age_group","sex"),1,"tb04_gpcr_agesex")

## OC and GP rates by ethnicity
tb05_gpcr_ethnicity <- df_to_tbrates(df_cleaned,c("ethnicity"),1,"tb05_gpcr_ethnicity")

## OC and GP rates by region and rurality
tb06_gpcr_care <- df_to_tbrates(df_cleaned,c("region","rural_urban"),1,"tb06_gpcr_ruc")

## OC and GP rates by care home status
tb07_gpcr_care <- df_to_tbrates(df_cleaned,c("care_home_type"),1,"tb07_gpcr_care")

## OC and GP rates by presence of disability
tb08_gpcr_dis <- df_to_tbrates(df_cleaned,c("has_disability"),1,"tb08_gpcr_dis")



## close log connection
#sink()


