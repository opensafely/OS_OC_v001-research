# ##==============================================================================
# Analysis filename:			02a-createredactedmeasure.R
# Project:				OC evaluation
# Author:				 Martina Fonseca. Using OC redactor
# Date: 					24/03/2021
# Version: 				R 
# Description:	Redact measures files
# Output to csv files
# Datasets used:			various 'measures*' files
# Datasets created:  various 'red_measure*' files'		
# Other output: 	TBA		
# Log file:  logs\log-02a-createredactedmeasure.txt
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-02a-createredactedmeasure.txt"))
## library
library(tidyverse)
library(here)
library(svglite)


# create directory for saving plots, if not existent
if (!dir.exists(here::here("output", "plots"))){
  dir.create(here::here("output", "plots"))
}
# create directory for saving plots, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}
print("dirs creation")

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
print("redactor function")

# create look-up table to iterate over
n_meas=10
md_tbl <- tibble(
  measure = c("gpc", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_computerlink","OC_alertreceived","OC_Y22b4"),
  measure_col=c("gp_consult_count", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_computerlink","OC_alertreceived","OC_Y22b4"),
  measure_label = c("GPconsult", "Y1f3b", "XUkjp", "XaXcK","XVCTw","XUuWQ","XV1pT","ComputerLink","AlertReceived","Y22b4"),
  by = rep("practice",1,n_meas),
  by_label = rep("by practice",1,n_meas),
  id = paste0(measure, "_", by),
  numerator = measure,
  denominator = "population",
  group_by = rep("practice",1,n_meas)
)
print("create tibble")

## import measures data from look-up
measures <- md_tbl %>%
  mutate(
    data = map(id, ~read_csv(here::here("output","measures", glue::glue("measure_{.}.csv")))),
  )
print("load data in tibble")

p_saving <- function(id,data) {
  write.csv(paste0(here::here("output","measures"),"/red_measure_",id,".csv"))
  return(data)
}

# Create redacted measures and save
measures <- measures %>%
  mutate(
    redacted_data = pmap(lst(id,measure_col,data),
                      function(id,measure_col,data) {
                        redacted_data <- data %>% mutate_at(vars(measure_col),redactor)
                        redacted_data$value <- ifelse(is.na(redacted_data %>% select(measure_col)),NA,redacted_data$value)
                        write.csv(redacted_data,paste0(here::here("output","tables"),"/redacted2a_measure_",id,".csv"))
                        return(redacted_data)
                      }
                      )
  )
print("load redacted data in tibble and save as csv's")

## close log connection
sink()
