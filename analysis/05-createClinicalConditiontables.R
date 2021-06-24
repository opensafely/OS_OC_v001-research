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
flag_lmtestoperational=TRUE
flag_sjplotoperational=FALSE

## library
library(tidyverse)
if (flag_gtsummaryoperational){
  library(gtsummary)  
}
library(gt)
library(here)
library(webshot)
if (flag_sjplotoperational){
  library(sjPlot) # to create goodlooking summary plots of OR/HR
}
library(sandwich) # robust errors
if (flag_lmtestoperational){
  library(lmtest)
}
library(modelsummary)
#webshot::install_phantomjs() # not supported

# create directory for saving tables, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}

## import and pre-process cohort data
df_input <- read_csv(
  here::here("output", "input_v2.csv"))

df_input <- df_input %>% rename(history_serious_mental_illness="serious_mental_illness_disease")

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


#### Re-level where appropriate
df_cleaned$ethnicity <- relevel(df_cleaned$ethnicity,ref="White")
df_cleaned$age_group <- relevel(df_cleaned$age_group,ref="(60,70]")
df_cleaned$sex <- relevel(df_cleaned$sex,ref="Male")


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
                      select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_pre_had","gp_consult_post_had"))
  
  (gt_econsult_pop_post <- study_pop_post %>%
      tbl_summary(by=econsult_post_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar20-Feb21**"))
  
  ## Characteristics of those with any OC consultation in the post period (pandemic), only for practices with any eConsultation coding recorded in that period
  study_pop_pre <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_pre_had,na.rm=T)!=0) %>% ungroup() %>%
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_pre_had","gp_consult_post_had"))
  
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
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_pre_had","gp_consult_post_had"))
  
  (gt_econsult_consultpop_post <- study_consultpop_post %>%
      tbl_summary(by=econsult_post_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)#**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar20-Feb21 (among those with an eConsult/GP consultation)**"))
  
  ## Characteristics of those with any OC consultation in the pre period (pre-pandemic), only for practices with any eConsultation coding recorded in that period. Compare those with either GPconsult or eConsult in that period
  study_consultpop_pre <- df_cleaned %>% group_by(practice) %>% filter(sum(econsult_pre_had,na.rm=T)!=0) %>% ungroup() %>%
    filter(econsult_pre_had>0|gp_consult_pre_had>0) %>%
    select(c(starts_with("history"),"econsult_pre_had","econsult_post_had","gp_consult_pre_had","gp_consult_post_had"))
  
  (gt_econsult_consultpop_pre <- study_consultpop_pre %>%
      tbl_summary(by=econsult_pre_had) %>% add_p() %>% add_overall() %>%
      modify_header(label="**Clinical history\n (pre-March 2019)#**") %>% modify_spanning_header(c("stat_1", "stat_2") ~ "**Had eConsultation code instance in Mar19-Feb20 (among those with an eConsult/GP consultation)**"))
  
  # Use function from gt package to save table as neat html
  gt::gtsave(as_gt(gt_econsult_consultpop_pre), file = file.path(here::here("output","tables"), "gt_econsult_consultpop_pre.html"))
  gt::gtsave(as_gt(gt_econsult_consultpop_post), file = file.path(here::here("output","tables"), "gt_econsult_consultpop_post.html"))
  
}  


###############################
#### Model for regression #####
################################


#vars_m <- c("ageg","Sex","ethn","IMD_Decile","high_capability")
outcomevar = "econsult_post_had"

explanatoryvar = colnames(df_cleaned) %>% as.tibble()
explanatoryvar = explanatoryvar %>% filter(substr(value,1,7)=="history" | value=="age_group" | value=="sex")


fmla <-
  as.formula(paste(outcomevar, paste(explanatoryvar$value, collapse = " + "
  ), sep = "~"))
print(fmla)

# Cohort: those in practices with at least an econsultation code instance in 20/21, those with either an econsult or GP consultation recorded.
data_model = df_cleaned %>% group_by(practice) %>% filter(sum(econsult_post_had,na.rm=T)!=0) %>% ungroup() %>%
  filter(econsult_post_had>0|gp_consult_post_had>0)

postglm <- glm(fmla,
               data = data_model,
               family=binomial)


print("standard errors")
print(summary(postglm))

print(anova(postglm,test="LRT"))
#chisq.test(postglm)

if (flag_sjplotoperational){
  plot_model(postglm,show.values=T, show.p=TRUE, ci.lvl=.95, value.offset = 0.5,robust=T,vcov.type="HC1",show.intercept=T,digits=3)# + scale_y_log10(limits = c(0.01, 1000))
}
  
# myglm_gt <- gtsummary::tbl_regression(postglm,exponentiate=TRUE) %>% add_global_p() %>% as_gt() %>%
#   gt::tab_source_note(gt::md("*Practices with at least one eConsultation instance in 20/21, comparator to patients with GP consultations in-year*"))
#   #set_summ_defaults(digits = 2, pvals = FALSE, robust = "HC1")
# myglm_gt
# 
# gt::gtsave(myglm_gt, file = file.path(here::here("output","tables"), "pracglm_submission.html"))


# https://vincentarelbundock.github.io/modelsummary/articles/modelsummary.html#exponentiated-coefficients-and-other-extras-
# https://vincentarelbundock.github.io/modelsummary/reference/modelsummary.html
modelsummary(postglm,exponentiate=TRUE,vcov=vcovHC(postglm, type="HC1"))
myglm_ms <- modelsummary(postglm,
                         vcov=vcovHC(postglm, type="HC1"),
                         #estimate="{estimate} [{conf.low}, {conf.high}]",
                         estimate="{estimate} {stars} [{conf.low}, {conf.high}]",
                         #statistic="{p.value} {stars} [{conf.low}, {conf.high}]",
                         statistic=NULL,
                         output="gt",
                         title="Practices with at least one eConsultation instance in 20/21, comparator to patients with GP consultations in-year")

gt::gtsave(myglm_ms, file = file.path(here::here("output","tables"), "pracglm_submission_rob_logit.html"))


if (flag_lmtestoperational){
  print("robust")
  print(coeftest(postglm, vcov = vcovHC(postglm, type="HC1")))
  
  a <- coeftest(postglm, vcov = vcovHC(postglm, type="HC1"))
  
  # https://github.com/tidymodels/broom/issues/663
  robustse <- function(o_glm, coef = c("logit", "odd.ratio")) {
    
    myvcov = vcovHC(postglm, type="HC1")
    
    a <- coeftest(postglm, vcov = myvcov )
    a<- as.data.frame(unclass(a))
    
    b <- coefci(postglm,vcov=myvcov)
    b <- as.data.frame(b)
    
    df_join <- a
    df_join$LCI95=b[,"2.5 %"]
    df_join$UCI95=b[,"97.5 %"]
    
    if (coef == "logit") {
      
      return(df_join) # return logit with robust SE's
    } else if (coef == "odd.ratio") {
      df_join[, 1] <- exp(df_join[, 1]) # return odd ratios with robust SE's
      df_join[, 2] <- df_join[, 1] * df_join[, 2]
      df_join[,c("LCI95")]=exp(df_join[,c("LCI95")])
      df_join[,c("UCI95")]=exp(df_join[,c("UCI95")])
      return(df_join)
    } 
  }
  
  mf_01 <- robustse(postglm,coef="odd.ratio")
  
  mf_01 <- cbind(Characteristic = rownames(mf_01), mf_01)
  rownames(mf_01) <- 1:nrow(mf_01)
  
  mf_01 <- mf_01 %>% mutate("s.s."=ifelse(`Pr(>|z|)`<0.05,"*",""))
  
  gt_tbl <- gt(mf_01 %>% select(-c("Std. Error","z value")) %>% mutate_if(is.numeric,~round(.,3))) %>% tab_header(
    title = "Adjusted odds of having had an online consultation in 20/21",
    subtitle = "Cohort: those in practices with eConsultation code activity,\n patients with either GP interaction or eConsultation"
  )
  gt_tbl
  
  # Use function from gt package to save table as neat png, save the original dataframe too
  gt::gtsave(gt_tbl, file = file.path(here::here("output","tables"), "pracglm_submission_rob.html"))
  write.csv(mf_01,file.path(here::here("output","tables"), "pracglm_submission_rob.csv"))
  
  
  # check only
  (mf_01 %>% mutate(checkLCI95=Estimate-qnorm(0.975)*`Std. Error`,
                    checkUCI95=Estimate+qnorm(0.975)*`Std. Error`))
  
  
}

## close log connection
sink()


