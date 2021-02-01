# ##==============================================================================
# Analysis filename:			03-createnattrends_codes
# Project:				Pilot on online consultation
# Author:					MF 
# Date: 					01/02/2020 (save as from vidclinic one)
# Version: 				R 
# Description:	Produce tally on instances of relevant codes over time (national trend)
# Output to csv files
# Datasets used:			input.csv
# Datasets created: 		None
# Other output: tables: 'tb*.csv'			
# Log file: log-03-createnattrends.txt
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-03-createnattrends.txt"))

## library
library(tidyverse)
library(here)
library(svglite)
`%!in%` = Negate(`%in%`)

query_dates=seq(as.Date("2019-01-01"),length=24,by="months")
query_dates <- paste0(query_dates)
## import and pre-process cohort data

df_input <- read_csv(
  here::here("output",paste0("input_measures_bycode_",  query_dates[1], ".csv")))
df_input <- df_input %>% mutate(month=query_dates[1])

for (datenow in tail(query_dates,-1)){
  df_input_now <- read_csv(
    here::here("output",paste0("input_measures_bycode_",  datenow, ".csv")))
  df_input_now <- df_input_now %>% mutate(month=datenow)
  df_input <- df_input %>% bind_rows(df_input_now)
}
df_input <- as.data.frame(df_input)
df_input <- df_input %>% rename(OC_gp_consult_count=gp_consult_count)
rm(df_input_now)

df_summary <- df_input %>%
  group_by(month) %>%
  summarise_at(vars(starts_with("OC")),~sum(.,na.rm=T))

df_summary_pop <- df_input %>% group_by(month) %>% summarise(OC_population=n())
df_summary <- left_join(df_summary,df_summary_pop,id="month")
rm(df_input)
rm(df_summary_pop)

df_summary_long <- df_summary %>% pivot_longer(cols=starts_with("OC"),
               names_to="Code",
               values_to="Count")
write.csv(df_summary_long,paste0(here::here("output"),"/sc03_tb01_nattrends.csv"))
# Disclosiveness: national monthly tally of clinical code occurrence, not deemed disclosive. 

df_summary_long$month <- as.Date(df_summary_long$month)
ggplot(data=df_summary_long,aes(x=month,y=Count,fill=Code)) +
  geom_bar(stat="identity") +
  facet_wrap(~Code,nrow=2,scales="free_y") +
  scale_x_date(date_breaks = "2 months",expand=c(0,0))  +
  theme(axis.text.x = element_text(angle = -90,vjust = 0))

ggsave(paste0(here::here("output"),"/sc03_fig01_nattrends.svg"),width = 40, height = 20, dpi=300,units ="cm")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 

ggplot(data=df_summary_long %>% filter(Code%!in% c("OC_gp_consult_count","OC_population")),aes(x=month,y=Count,color=Code)) +
   geom_line()+
  scale_x_date(date_breaks = "2 months",expand=c(0,0))+
  theme(axis.text.x = element_text(angle = -90,vjust = 0))

ggsave(paste0(here::here("output"),"/sc03_fig02_nattrends.svg"),width = 40, height = 20, dpi=300,units ="cm")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 


## close log connection
sink()
