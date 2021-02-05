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
sink(here::here("logs", "log-02-createtemporal.txt"))
## library
library(tidyverse)
library(here)
library(svglite)


# create look-up table to iterate over
md_tbl <- tibble(
  measure = c("gpc", "OC_Y1f3b", "OC_XUkjp", "OC_XaXcK","OC_XVCTw","OC_XUuWQ","OC_XV1pT","OC_9N34d","OC_d9N34","OC_XUman","OC_Y22b4"),
  measure_label = c("GPconsult", "Y1f3b", "XUkjp", "XaXcK","XVCTw","XUuWQ","XV1pT","9N34d","d9N34","XUman","Y22b4"),
  by = rep("practice",1,11),
  by_label = rep("by practice",1,11),
  id = paste0(measure, "_", by),
  numerator = measure,
  denominator = "population",
  group_by = rep("practice",1,11)
)

## import measures data from look-up
measures <- md_tbl %>%
  mutate(
    data = map(id, ~read_csv(here::here("output","measures", glue::glue("measure_{.}.csv")))),
  )

measures_gpc_pratice <- measures$data[[match("gpc_practice",measures$id)]]

measures_gpc_pop <- 
  measures_gpc_pratice %>%
  group_by(date) %>%
  summarise(population=sum(population),gp_consult_count=sum(gp_consult_count),value=gp_consult_count/population)
write.csv(measures_gpc_pop,paste0(here::here("output"),"/measures_gpc_pop.csv"))

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
  filename = str_c("plot_overall_gpc_pop.svg"),
  path = here::here("output", "plots"))


quibble <- function(x, q = c(0.25, 0.5, 0.75)) {
  ## function that takes a vector and returns a tibble of quantiles - default is quartile
  tibble("{{ x }}" := quantile(x, q), "{{ x }}_q" := q)
}

# v_median <- function(v_quantiles) {
#   ### function that takes quantiles and extracts median
#   v_quantiles %>% filter(mvalue_q==0.5) %>% .$mvalue
# }

v_median <- function(x) {
  tibble(median := quantile(x,0.5))
}

v_idr <- function(x){
  tibble(IDR := quantile(x,0.9)-quantile(x,0.1))
}

## generate plots for each measure within the data frame
measures_plots <- measures %>% 
  mutate(
    data_quantiles = map(data, ~ (.) %>% group_by(date) %>% summarise(quibble(value, seq(0,1,0.1)),v_idr(value),v_median(value))),
    #data_median = map(data_quantiles, ~ (.) %>% group_by(date) %>% filter(value_q==0.5) %>% transmute(median=value)),
    data_idr = map(data, ~ (.) %>% group_by(date) %>% summarise(v_idr(value),v_median(value))),
    plot_by = pmap(lst( group_by, data, measure_label, by_label), 
                   function(group_by, data, measure_label, by_label){
                     data %>% mutate(value_10000 = value*10000) %>%
                       ggplot()+
                       geom_line(aes_string(x="date", y="value_10000", group=group_by), alpha=0.2, colour='blue', size=0.25)+
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
    ),
    plot_quantiles = pmap(lst( group_by, data_quantiles, measure_label, by_label), 
                          function(group_by, data_quantiles, measure_label, by_label){
                            data_quantiles %>% mutate(value_10000 = value*10000) %>%
                              ggplot()+
                              geom_line(aes(x=date, y=value_10000, group=value_q, linetype=value_q==0.5, size=value_q==0.5), colour='blue')+
                              scale_linetype_manual(breaks=c(TRUE, FALSE), values=c("solid", "dotted"), guide=FALSE)+
                              scale_size_manual(breaks=c(TRUE, FALSE), values=c(1, 0.4), guide=FALSE)+
                              scale_x_date(date_breaks = "1 month", labels = scales::date_format("%Y-%m"))+
                              labs(
                                x=NULL, y=NULL, 
                                title=glue::glue("{measure_label} instances per 10,000 patients"),
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
    )
  )


## plot the charts (by variable)
measures_plots %>%
  transmute(
    plot = plot_by,
    units = "cm",
    height = 10,
    width = 15, 
    limitsize=FALSE,
    filename = str_c("plot_each_", id, ".svg"),
    path = here::here("output", "plots"),
  ) %>%
  pwalk(ggsave)


## plot the charts (by quantile)
measures_plots %>%
  transmute(
    plot = plot_quantiles,
    units = "cm",
    height = 10,
    width = 15, 
    limitsize=FALSE,
    filename = str_c("plot_quantiles_", id, ".svg"),
    path = here::here("output", "plots"),
  ) %>%
  pwalk(ggsave)


## close log connection
sink()
