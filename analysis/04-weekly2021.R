# ##==============================================================================
# Analysis filename:			04-weekly2021.R
# Project:				Pilot on online consultation
# Author:					MF 
# Date: 					14/04/2021
# Version: 				R 
# Description:	Bring together three measures files (weekly national tally of 3 activity types). Apply redaction
# Output to csv files
# Datasets used:			measures_weekly* files
# Datasets created: 		None
# Other output: tables: 'tb*.csv'			
# Log file: log-04-weekly2021.txt
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-04-weekly2021.txt"))


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

query_dates=seq(as.Date("2019-01-01"),length=24,by="months")
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


## import and pre-process cohort data (bring together measures files)

df_input <- read_csv(here::here("output","measures-week","measure_gpc_rate.csv")) %>%
  mutate(Code="gp_consult_count") %>%
  rename(Count=gp_consult_count)

df_now <- read_csv(here::here("output","measures-week","measure_snomed_eConsult_rate.csv")) %>%
  mutate(Code="snomed_eConsult") %>%
  rename(Count=snomed_eConsult)

df_input <- df_input %>% bind_rows(df_now)

df_now <- read_csv(here::here("output","measures-week","measure_snomed_OCall_all.csv"))%>%
  mutate(Code="snomed_OCall") %>%
  rename(Count=snomed_OCall)

df_input <- df_input %>% bind_rows(df_now)

# Leave only national TPP information rather than regional
df_output <- df_input %>% group_by(Code,date) %>% summarise(Count=sum(Count,na.rm=T),population=sum(population,na.rm=T)) %>% ungroup()

# Redact (<6 rule)
df_output <- df_output %>% mutate_at(vars(population,Count),redactor)

# Save redacted file
write.csv(df_output,paste0(here::here("output","tables"),"/sc04-weeklynattrend.csv")) # National weekly counts and rates of 3 codes. Redaction applied to <6.

## close log connection
sink()

