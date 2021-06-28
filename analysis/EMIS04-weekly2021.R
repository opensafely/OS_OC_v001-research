# ##==============================================================================
# Project:				Pilot on online consultation
# Author:					MF 
# Date: 					14/06/2021
# Version: 				R 
# Description:	Bring together three measures files (weekly national tally of 3 activity types). Apply redaction
# Output to csv files
# Datasets used:			measures_weekly* files
# Datasets created: 		None
# Other output: tables: 'tb*.csv'			
# Log file: log-EMIS04-weekly2021.txt
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-EMIS04-weekly2021.txt"))


# create directory for saving tables, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}
print("directories cleared")

## library
library(tidyverse)
library(here)
library(svglite)
`%!in%` = Negate(`%in%`)

query_dates=seq(as.Date("2020-01-06"),length=74,by="weeks")
query_dates <- paste0(query_dates)
print("Libraries loaded. Query dates established.")

## Redactor code (W.Hulme)
redactor <- function(n, threshold=6,e_overwrite=NA_integer_){
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
  n_redacted <- if_else(redact, e_overwrite, n)
}
print("Redactor defined")



### bring in names and shorthands for codes
snomed_label=read.csv(here("codelists-local","martinaf-online-consultations-snomed-v01-28bba9bc_min_short.csv"))
snomed_label <- cbind(codeid = rownames(snomed_label), snomed_label)
rownames(snomed_label) <- NULL
snomed_label <- bind_rows(snomed_label,tibble(codeid="OCall",code="All codes",term="All codes"))





## import and pre-process cohort data (bring together measures files)

i=1
suffix = paste0("snomed_",snomed_label[i,1])
df_input <- read_csv(here::here("output","emismeasures-weekly",paste0("measure_",suffix,"_practice.csv"))) %>%
  mutate(Code=snomed_label[i,1]) %>%
  rename(Count=suffix)


for (i in 2:nrow(snomed_label)){
  
  suffix = paste0("snomed_",snomed_label[i,1])
  df_now <- read_csv(here::here("output","emismeasures-weekly",paste0("measure_",suffix,"_practice.csv"))) %>%
    mutate(Code=snomed_label[i,1]) %>%
    rename(Count=suffix)
  
  df_input <- bind_rows(df_input,df_now)
  
}

# Leave only national TPP information rather than regional
df_output <- df_input %>% group_by(Code,date) %>% summarise(Count=sum(Count,na.rm=T),population=sum(population,na.rm=T)) %>% ungroup()

# Redact (<6 rule)
df_output <- df_output %>% mutate_at(vars(population,Count),redactor)

# Add shorthand
df_output <- df_output %>% left_join(snomed_label,by=c("Code"="codeid"))

# Save redacted file
write.csv(df_output,paste0(here::here("output","tables"),"/EMISsc04-weeklynattrend.csv")) # National weekly counts and rates of 3 codes. Redaction applied to <6.

## close log connection
sink()

