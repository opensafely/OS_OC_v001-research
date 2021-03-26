# ##==============================================================================
# Analysis filename:			02-createtemporal.R
# Project:				OC evaluation
# Author:					Heavily lifted from W. Hulme Tutorial example 3. Minor adaptations: Martina Fonseca
# Date: 					17/12/2020 (updated: 02/02/2021)
# Version: 				R 
# Description:	Produce timeline of of GP consultation and OC instance rates
# Output to csv files
# Datasets used:			various 'measures*' files
# Datasets created:  'measures_gpc_pop.csv'		
# Other output: 	TBA		
# Log file:  logs\log-02-createtemporal.txt
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-02-createtemporal-debug.txt"))
## library
library(tidyverse)
library(here)
library(svglite)
print("> Libraries")

# create directory for saving plots, if not existent
if (!dir.exists(here::here("output", "plots"))){
  dir.create(here::here("output", "plots"))
}
# create directory for saving plots, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}
print("> Dirs")

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
print("> Redactor def")

# create look-up table to iterate over
# n_meas=10
# md_tbl <- tibble(
#   measure = c("gpc", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_computerlink","OC_alertreceived","OC_Y22b4"),
#   measure_col=c("gp_consult_count", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_computerlink","OC_alertreceived","OC_Y22b4"),
#   measure_label = c("GPconsult", "Y1f3b", "XUkjp", "XaXcK","XVCTw","XUuWQ","XV1pT","ComputerLink","AlertReceived","Y22b4"),
#   by = rep("practice",1,n_meas),
#   by_label = rep("by practice",1,n_meas),
#   id = paste0(measure, "_", by),
#   numerator = measure,
#   denominator = "population",
#   group_by = rep("practice",1,n_meas)
# )
# n_meas=8
# md_tbl <- tibble(
#   measure = c("gpc", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_Y22b4"),
#   measure_col=c("gp_consult_count", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_Y22b4"),
#   measure_label = c("GPconsult", "Y1f3b", "XUkjp", "XaXcK","XVCTw","XUuWQ","XV1pT","Y22b4"),
#   by = rep("practice",1,n_meas),
#   by_label = rep("by practice",1,n_meas),
#   id = paste0(measure, "_", by),
#   numerator = measure,
#   denominator = "population",
#   group_by = rep("practice",1,n_meas)
# )
n_meas=5
md_tbl <- tibble(
  measure = c("gpc", "OC_Y1f3b","OC_Y22b4","OC_XaXcK","OC_computerlink"),
  measure_col=c("gp_consult_count", "OC_Y1f3b","OC_Y22b4","OC_XaXcK","OC_computerlink"),
  measure_label = c("GPconsult", "OC_Y1f3b","OC_Y22b4","OC_XaXcK","OC_computerlink"),
  by = rep("practice",1,n_meas),
  by_label = rep("by practice",1,n_meas),
  id = paste0(measure, "_", by),
  numerator = measure,
  denominator = "population",
  group_by = rep("practice",1,n_meas)
)
print("> Tibble creation")

## import measures data from look-up
measures <- md_tbl %>%
  mutate(
    data = map(id, ~read_csv(here::here("output","measures", glue::glue("measure_{.}.csv")))),
  )
print("> Data load to measures")

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
                        write.csv(redacted_data,paste0(here::here("output","tables"),"/redacted_measure_",id,".csv"))
                        return(redacted_data)
                      }
                      )
  )
print("> Redacted measures")

#measures_m <- measures %>% mutate(no_2020_events = map(data, ~ (.) %>% filter(as.numeric(format(date,'%Y'))==2020))  ) 

#measures_m <- measures %>% mutate(no_2020_events = map(data, ~ (.) %>% filter(as.numeric(format(date,'%Y'))==2020) %>% select(value) %>% sum()  )) 

measures <- measures %>% mutate(no_2020_events = pmap(lst( data, measure_col), 
                                  function(data, measure_col){
                                    
                                    data %>% filter(as.numeric(format(date,'%Y'))==2020) %>% select(measure_col) %>% sum()
                                    }
                                  )) 
print("> 2020 events")

#measures_m <- measures %>% mutate(no_2020_events = map(data,  ~ (.) %>% group_by(date)))


measures_gpc_pratice <- measures$data[[match("gpc_practice",measures$id)]]

measures_gpc_pop <- 
  measures_gpc_pratice %>%
  group_by(date) %>%
  summarise(population=sum(population),gp_consult_count=sum(gp_consult_count),value=gp_consult_count/population)
write.csv(measures_gpc_pop,paste0(here::here("output"),"/measures_gpc_pop_debug.csv")) # National monthly GP consultation instances. Suppression not needed.

measures_gpc_pop %>% mutate(value_10000 = value*10000) %>%
  ggplot()+
  geom_line(aes_string(x="date", y="value_10000"), alpha=0.2, colour='blue', size=0.25)+
  scale_x_date(date_breaks = "1 month", labels = scales::date_format("%Y-%m"))+
  labs(
    x=NULL, y=NULL, 
    title="GP consultation instances",
    subtitle =  glue::glue("GP consulation rate per 10,000 patients")
  )+
  theme_bw()+
  theme(
    panel.border = element_blank(),
    axis.text.x = element_text(angle = 70, vjust = 1, hjust=1),
  )
ggsave(
  units = "cm",
  height = 10,
  #width = 15, 
  limitsize=FALSE,
  filename = str_c("plot_overall_gpc_pop_debug.svg"),
  path = here::here("output", "plots"))  # National monthly GP consultation instances. Suppression not needed.
print("> General practice plots and data")

#### Excluding practices with no code instances over full tenor of study period
#mydata <- measures$data[[1]]
#mydata <- rbind(mydata, mydata %>% group_by(date) %>% summarise(gp_consult_count=0,population=10000,value=0,practice=999) )

#mydata <- mydata %>% group_by(practice) %>% mutate(code_present = ifelse(sum(value,na.rm=T)>0,1,0) ) %>% ungroup()

#mydata <- mydata %>% group_by(practice) %>% filter(sum(value,na.rm=T)>0)


measures <- measures %>% mutate(
  data_ori=data, # data with all practices
  data = map(data, ~ (.) %>% group_by(practice) %>% filter(sum(value,na.rm=T)>0)), # data with only practices with at least an observation in the study period (affects deciles)
  no_prac = map(data, ~(.) %>% .$practice %>% n_distinct(na.rm=T) ),
  no_prac_univ = map(data_ori, ~(.) %>% .$practice %>% n_distinct(na.rm=T))
)
print("> Summary tallies")


quibble <- function(x, q = c(0.25, 0.5, 0.75)) {
  ## function that takes a vector and returns a tibble of quantiles - default is quartile
  print("> Quibble in")
  
  tibble("{{ x }}" := quantile(x, q), "{{ x }}_q" := q)
}

quibble_catch <- function(x, q = c(0.25, 0.5, 0.75)) {
  ## function that takes a vector and returns a tibble of quantiles - default is quartile
  print("> Quibble in")
  out <- tryCatch(tibble("{{ x }}" := quantile(x, q), "{{ x }}_q" := q),
                  error=function(e) tibble("{{ x }}" := quantile(c(0,0), q), "{{ x }}_q" := q))
  return(out)
}

# v_median <- function(v_quantiles) {
#   ### function that takes quantiles and extracts median
#   v_quantiles %>% filter(mvalue_q==0.5) %>% .$mvalue
# }

v_median <- function(x) {
  print("> Median in")
  #tibble(median := quantile(x,0.5))
  out <- tryCatch(tibble(median := quantile(x,0.5)),
                  error=function(e) tibble(median := 0))
  return(out)
}

v_idr <- function(x){
  print("> IDR in")
  #tibble(IDR := quantile(x,0.9)-quantile(x,0.1))
  out <- tryCatch(tibble(IDR := quantile(x,0.9)-quantile(x,0.1)),
                  error=function(e) tibble(IDR := 0))
  return(out)
}

str_medidrnarrative <- function(mydata_idr){
  print("> medidrnarrative in")
  
  a<- mydata_idr %>%
    summarise(date,medchange = (median - lag(median,12))/lag(median,12)*100  ) %>% 
    mutate(classification=case_when(
      between(medchange,-15,15) ~ "no change",
      medchange>15 ~ "increase",
      medchange<(-60) ~ "large drop",
      medchange<(-15) ~ "drop",
      TRUE ~ NA_character_,
    ) )
  
  print("> medidrnarrative mid")

  
  paste0("Change in median from 2019: April ",
         round(as.numeric(a[a$date=="2020-04-01","medchange"]),1),"% (",a[a$date=="2020-04-01","classification"],"); ",
         "September ",round(as.numeric(a[a$date=="2020-09-01","medchange"]),1),"% (",a[a$date=="2020-09-01","classification"],"); ",
         "December ", round(as.numeric(a[a$date=="2020-12-01","medchange"]),1),"% (",a[a$date=="2020-12-01","classification"],");")
  
}





## generate plots for each measure within the data frame
measures_plots <- measures %>% 
  mutate(
    data_quantiles = map(data, ~ (.) %>% group_by(date)))
                         #%>% summarise(quibble_catch(value, seq(0,1,0.1)))))

measures_plots <- measures %>% 
  mutate(
    data_quantiles = map(data, 
                         function(data){
                           out <- tryCatch(data %>% group_by(date) %>% summarise(quibble_catch(value, seq(0,1,0.1))),
                                           error=function(e) data %>% group_by(date) %>% summarise(quibble_catch(c(0,0), seq(0,1,0.1))))
                           return(out)
                         }))
#%>% summarise(quibble_catch(value, seq(0,1,0.1)))))

print("> tibble mapping of deciles")
flag_run=T

if(flag_run){
    ###data_median = map(data_quantiles, ~ (.) %>% group_by(date) %>% filter(value_q==0.5) %>% transmute(median=value)),
 measures_plots <- measures_plots %>% 
   mutate(
     data_idr = map(data, ~ (.) %>% group_by(date) %>% summarise(v_idr(value*1000),v_median(value*1000))))
 
 print("> tibble mapping of median , idr")

measures_plots <- measures_plots %>% 
  mutate(
    plot_by = pmap(lst( group_by, data, measure_label, by_label), 
                   function(group_by, data, measure_label, by_label){
                     data %>% mutate(value_1000 = value*1000) %>%
                       ggplot()+
                       geom_line(aes_string(x="date", y="value_1000", group=group_by), alpha=0.2, colour='blue', size=0.25)+
                       scale_x_date(date_breaks = "1 month", labels = scales::date_format("%Y-%m"))+
                       labs(
                         x=NULL, y=NULL, 
                         title=glue::glue("{measure_label} measurement"),
                         subtitle =  glue::glue("{by_label}, per 10,000 patients")
                       )+
                       theme_bw()+
                       theme(
                         panel.border = element_blank(), 
                         axis.line.x = element_line(colour = "black"),
                         axis.text.x = element_text(angle = 70, vjust = 1, hjust=1),
                         panel.grid.major.x = element_blank(),
                         panel.grid.minor.x = element_blank(),
                       )
                   }
    ))

print("> tibble mapping of plots")

measures_plots <- measures_plots %>% 
  mutate(
    plot_quantiles = pmap(lst( group_by, data_quantiles, measure_label, by_label), 
                          function(group_by, data_quantiles, measure_label, by_label){
                            data_quantiles %>% mutate(value_1000 = value*1000) %>%
                              ggplot()+
                              geom_line(aes(x=date, y=value_1000, group=value_q, linetype=value_q==0.5, size=value_q==0.5), colour='blue')+
                              scale_linetype_manual(breaks=c(TRUE, FALSE), values=c("solid", "dotted"), guide=FALSE)+
                              scale_size_manual(breaks=c(TRUE, FALSE), values=c(1, 0.4), guide=FALSE)+
                              scale_x_date(date_breaks = "1 month", labels = scales::date_format("%Y-%m"))+
                              labs(
                                x=NULL, y=NULL, 
                                title=glue::glue("{measure_label} instances per 1000 patients"),
                                subtitle = glue::glue("quantiles {by_label}")
                              )+
                              theme_bw()+
                              theme(
                                panel.border = element_blank(), 
                                axis.line.x = element_line(colour = "black"),
                                axis.text.x = element_text(angle = 70, vjust = 1, hjust=1),
                                panel.grid.major.x = element_blank(),
                                panel.grid.minor.x = element_blank(),
                                #axis.line.y = element_blank(),
                              )
                          }
    ))

print("> tibble mapping of decile plots")

measures_plots <- measures_plots %>%
  mutate(
    plot_quantiles2 = pmap(lst( group_by, data_quantiles, measure_label, by_label,data_idr,no_2020_events,no_prac,no_prac_univ),
                          function(group_by, data_quantiles, measure_label, by_label,data_idr,no_2020_events,no_prac,no_prac_univ){
                            data_quantiles %>% mutate(value_1000 = value*1000) %>%
                              ggplot()+
                              geom_line(aes(x=date, y=value_1000, group=value_q, linetype=value_q==0.5, size=value_q==0.5), colour='blue')+
                              scale_linetype_manual(breaks=c(TRUE,FALSE), values=c("solid", "dashed"), guide=FALSE,labels=c("median","decile"))+
                              scale_size_manual(breaks=c(TRUE, FALSE), values=c(1, 0.5), guide=FALSE)+
                              scale_x_date(date_breaks = "1 month", labels = scales::date_format("%Y-%m"))+
                              labs(
                                x=NULL,
                                y="rate per 1,000",
                                linetype="metric",
                                title=glue::glue("{measure_label}"),
                                subtitle = paste0(
                                  "Practices included: ",
                                  no_prac, " (",round(no_prac/no_prac_univ*100,1),"%)",
                                  "; 2020 events: ",
                                  paste0(round(no_2020_events/1000,1),"k"),
                                  "; 2020 patients: ",
                                  "TBA"
                                ),
                                caption=paste0("Feb median: ",
                                               round(data_idr %>% filter(date=="2020-02-01") %>% .$median ,1),
                                               " (IDR ",
                                               round(data_idr %>% filter(date=="2020-02-01") %>% .$IDR ,1),"), ",
                                               "April median: ",
                                               round(data_idr %>% filter(date=="2020-04-01") %>% .$median ,1),
                                               " (IDR ",
                                               round(data_idr %>% filter(date=="2020-04-01") %>% .$IDR ,1),"),\n ",
                                               "September median: ",
                                               round(data_idr %>% filter(date=="2020-09-01") %>% .$median ,1),
                                               " (IDR ",
                                               round(data_idr %>% filter(date=="2020-09-01") %>% .$IDR ,1),"), ",
                                               "December median: ",
                                               round(data_idr %>% filter(date=="2020-12-01") %>% .$median ,1),
                                               " (IDR ",
                                               round(data_idr %>% filter(date=="2020-12-01") %>% .$IDR ,1),")\n",
                                               str_medidrnarrative(data_idr)
                                               )
                              )+
                              theme_bw()+
                              theme(
                                panel.border = element_blank(),
                                axis.line.x = element_line(colour = "black"),
                                axis.text.x = element_text(angle = 70, vjust = 1, hjust=1),
                                panel.grid.major.x = element_blank(),
                                panel.grid.minor.x = element_blank(),
                                axis.line.y = element_blank(),
                                plot.caption = element_text(color = "gray64", size=7)
                              )
                          }
    )
  )

print("> tibble mapping of decile plots - mfenriched")

## plot the charts (by variable)
# measures_plots %>%
#   transmute(
#     plot = plot_by,
#     units = "cm",
#     height = 10,
#     width = 15, 
#     limitsize=FALSE,
#     filename = str_c("plot_each_debug_", id, ".svg"),
#     path = here::here("output", "plots"),
#   ) %>%
#   pwalk(ggsave)
#print("> measure_plots_saved")

## plot the charts (by quantile)
measures_plots %>%
  transmute(
    plot = plot_quantiles,
    units = "cm",
    height = 10,
    width = 15,
    limitsize=FALSE,
    filename = str_c("plot_quantiles_debug_", id, ".svg"),
    path = here::here("output", "plots"),
  ) %>%
  pwalk(ggsave)
print("> measure_quantiles_saved")

## plot the charts (by quantile)
measures_plots %>%
  transmute(
    plot = plot_quantiles2,
    units = "cm",
    height = 10,
    width = 15,
    limitsize=FALSE,
    filename = str_c("plot_quantiles2_debug_", id, ".svg"),
    path = here::here("output", "plots"),
  ) %>%
  pwalk(ggsave)
print("> measure_quantiles2_saved")

}

## close log connection
sink()
