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

# create directory for saving plots, if not existent
if (!dir.exists(here::here("output", "plots"))){
  dir.create(here::here("output", "plots"))
}
# create directory for saving plots, if not existent
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
redactor <- function(n, threshold,e_overwrite=NA_integer_){
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


## import and pre-process cohort data

df_input <- read_csv(
  here::here("output","measures",paste0("input_measures_bycode_",  query_dates[1], ".csv")))
df_input <- df_input %>% mutate(population=1) %>% group_by(region,stp,practice) %>% summarise_all(~sum(.,na.rm=T)) %>% ungroup()
df_input <- df_input %>% mutate(month=query_dates[1]) %>% select(-patient_id)
print(here::here("output","measures",paste0("input_measures_bycode_",  query_dates[1], ".csv")))

for (datenow in tail(query_dates,-1)){
  df_input_now <- read_csv(
    here::here("output","measures",paste0("input_measures_bycode_",  datenow, ".csv")))
  print(here::here("output","measures",paste0("input_measures_bycode_",  datenow, ".csv")))
  print("loaded")
  df_input_now <- df_input_now %>% mutate(population=1) %>% group_by(region,stp,practice) %>% summarise_all(~sum(.,na.rm=T)) %>% ungroup()
  print("aggregated")
  df_input_now <- df_input_now %>% mutate(month=datenow) %>% select(-patient_id)
  df_input_now <- df_input_now %>% mutate(month=datenow)
  print("mutated")
  df_input <- df_input %>% bind_rows(df_input_now)
  print("bound to master")
}
df_input <- as.data.frame(df_input)
#df_input <- df_input %>% rename(snomedc_gp_consult_count=gp_consult_count)
print(df_input %>% select_if(is.numeric) %>% summarise_all(~sum(.,na.rm=T)))
print(summary(df_input))
print(head(df_input,0))
rm(df_input_now)

df_summary <- df_input %>%
  group_by(month,practice) %>%
  summarise_at(vars(starts_with("snomed"),starts_with("OC"),population,gp_consult_count),~sum(.,na.rm=T))
print("summary created -a")
#df_summary_pop <- df_input %>% group_by(month) %>% summarise(OC_population=n_distinct(patient_id))
#print("summary created -b")
#df_summary <- left_join(df_summary,df_summary_pop,id="month")
#print("summary created -c")

#rm(df_summary_pop)


#### SNOMED - practice coverage ###
myprefix="snomed"

## Calculations for practice coverage
df_practice_flags <- df_input %>% group_by(region,stp,practice) %>% summarise_at(vars(starts_with(myprefix)),~ifelse(sum(.,na.rm=T)>0,1,0))
print("practice calc 1")

tbx_practice_flags_ <- pivot_longer(df_practice_flags,cols=starts_with(myprefix),
                                     names_to="code",
                                     values_to="had_instance")
print("practice calc 2")

tbx_practice_flags_reg <- tbx_practice_flags_ %>%
  group_by(region,code) %>%
  summarise(Present=sum(had_instance),Absent=n()-Present) %>%
  pivot_longer(c("Present","Absent"),names_to="Instance presence",values_to="no_practices") %>%
  mutate(code=substr(code,nchar(myprefix)+2,nchar(code)))
print("practice calc 3")

tbx_practice_flags_ <- tbx_practice_flags_ %>%
  group_by(code) %>%
  summarise(Present=sum(had_instance),Absent=n()-Present) %>%
  pivot_longer(c("Present","Absent"),names_to="Instance presence",values_to="no_practices") %>%
  mutate(code=substr(code,nchar(myprefix)+2,nchar(code)))
print("practice calc 4")

tbx_practice_flags_$`Instance presence` <- factor(tbx_practice_flags_$`Instance presence`)
print("practice calc 5")

ggplot(tbx_practice_flags_, aes(fill=`Instance presence`,x=code, y=no_practices,label=no_practices)) +
  geom_bar( stat="identity")+
  geom_text(aes(vjust=0),position = position_stack(vjust = 0.2))+
  theme(axis.text.x = element_text(angle = -90),text = element_text(size=15))+
  labs(title="Portion of practices with code recorded",y="Count of practices",x="Code")+
  coord_flip()
print("practice fig03 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig03_pracnatcoverage.svg"),width = 30, height = 20, dpi=300,units ="cm")
print("practice fig03 saved")

ggplot(tbx_practice_flags_reg, aes(fill=`Instance presence`,x=code, y=no_practices,label=no_practices)) +
  geom_bar( stat="identity")+
  geom_text(aes(hjust=-1),position = position_stack(vjust = 0.0))+
  theme(axis.text.x = element_text(angle = -90),text = element_text(size=15))+
  labs(title="Portion of practices with code recorded",y="Count of practices",x="Code")+facet_wrap(~region)+
  coord_flip()
print("practice fig04 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig04_pracbyregcoverage.svg"),width = 30, height = 30, dpi=300,units ="cm")
print("practice fig04 saved")

#rm(df_input)
rm(df_practice_flags)
rm(tbx_practice_flags_)
rm(tbx_practice_flags_reg)


#### CTV3 - practice coverage ###
myprefix="OC"

## Calculations for practice coverage
df_practice_flags <- df_input %>% group_by(region,stp,practice) %>% summarise_at(vars(starts_with(myprefix)),~ifelse(sum(.,na.rm=T)>0,1,0))
print("practice calc 1")

tbx_practice_flags_ <- pivot_longer(df_practice_flags,cols=starts_with(myprefix),
                                    names_to="code",
                                    values_to="had_instance")
print("practice calc 2")

tbx_practice_flags_reg <- tbx_practice_flags_ %>%
  group_by(region,code) %>%
  summarise(Present=sum(had_instance),Absent=n()-Present) %>%
  pivot_longer(c("Present","Absent"),names_to="Instance presence",values_to="no_practices") %>%
  mutate(code=substr(code,nchar(myprefix)+2,nchar(code)))
print("practice calc 3")

tbx_practice_flags_ <- tbx_practice_flags_ %>%
  group_by(code) %>%
  summarise(Present=sum(had_instance),Absent=n()-Present) %>%
  pivot_longer(c("Present","Absent"),names_to="Instance presence",values_to="no_practices") %>%
  mutate(code=substr(code,nchar(myprefix)+2,nchar(code)))
print("practice calc 4")

tbx_practice_flags_$`Instance presence` <- factor(tbx_practice_flags_$`Instance presence`)
print("practice calc 5")

ggplot(tbx_practice_flags_, aes(fill=`Instance presence`,x=code, y=no_practices,label=no_practices)) +
  geom_bar( stat="identity")+
  geom_text(aes(vjust=0),position = position_stack(vjust = 0.2))+
  theme(axis.text.x = element_text(angle = -90),text = element_text(size=15))+
  labs(title="Portion of practices with code recorded",y="Count of practices",x="Code")+
  coord_flip()
print("practice fig05 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig05_ctv3pracnatcoverage.svg"),width = 30, height = 20, dpi=300,units ="cm")
print("practice fig05 saved")

ggplot(tbx_practice_flags_reg, aes(fill=`Instance presence`,x=code, y=no_practices,label=no_practices)) +
  geom_bar( stat="identity")+
  geom_text(aes(hjust=-1),position = position_stack(vjust = 0.0))+
  theme(axis.text.x = element_text(angle = -90),text = element_text(size=15))+
  labs(title="Portion of practices with code recorded",y="Count of practices",x="Code")+facet_wrap(~region)+
  coord_flip()
print("practice fig06 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig06_ctv3pracbyregcoverage.svg"),width = 30, height = 30, dpi=300,units ="cm")
print("practice fig06 saved")


#### National trends - snomed ####
myprefix="snomed"
df_summary_long <- df_summary %>% pivot_longer(cols=c("gp_consult_count",union(starts_with("snomed"),starts_with("oc"))),
                                               names_to="Code",
                                               values_to="Count")
print("national calc 1")

df_summary_long <- df_summary_long %>% ungroup() %>% group_by(month,Code) %>%
  summarise(populationTPP=sum(population,na.rm=T),
            practices=n_distinct(practice),
            practicewithcode=sum(ifelse(Count>0,1,0)),
            practicecoverage=practicewithcode/practices*100,
            populationpracwithcode=sum(ifelse(Count>0,population,0)),
            Count=sum(Count,na.rm=T))
df_summary_long_s <- df_summary_long
df_summary_long_s$Count <- redactor(df_summary_long_s$Count,threshold =6,e_overwrite=NA_integer_)
df_summary_long_s <- df_summary_long_s %>% mutate(populationpracwithcode=ifelse(practicewithcode==1,NA_integer_,populationpracwithcode)) 
print("national calc2")
write.csv(df_summary_long_s,paste0(here::here("output","tables"),"/sc03_tb01_nattrends.csv"))
print("national calc saved")
# Disclosiveness: national monthly tally of clinical code occurrence, not deemed disclosive. 

df_summary_long$month <- as.Date(df_summary_long$month)
df_summary_long <- df_summary_long %>% mutate(rate_per_1000=Count/populationTPP*1000)
ggplot(data=df_summary_long %>% filter(Code=="gp_consult_count"|substr(Code,1,nchar(myprefix))==myprefix),aes(x=month,y=rate_per_1000,group=Code)) +
  geom_bar(stat="identity",fill="#56B4E9") +
  facet_wrap(~Code,nrow=4,scales="free_y") +
  labs(y="Instance rate (per 1,000)")+
  scale_x_date(date_breaks = "2 months",expand=c(0,0))  +
  theme(axis.text.x = element_text(angle = -90,vjust = 0))
print("national fig01 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig01_nattrends.svg"),width = 30, height = 30, dpi=300,units ="cm")
print("national fig01 saved")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 

ggplot(data=df_summary_long %>% filter(substr(Code,1,nchar(myprefix))==myprefix),aes(x=month,y=rate_per_1000,color=Code)) +
   geom_line()+
  scale_x_date(date_breaks = "2 months",expand=c(0,0))+
  labs(y="Instance rate (per 1,000)")+
  theme(axis.text.x = element_text(angle = -90,vjust = 0))
print("national fig02 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig02_nattrends.svg"),width = 40, height = 20, dpi=300,units ="cm")
print("national fig02 saved")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 


#### National trends - ctv3 ####
myprefix="OC"
ggplot(data=df_summary_long %>% filter(Code=="gp_consult_count"|substr(Code,1,nchar(myprefix))==myprefix),aes(x=month,y=rate_per_1000,group=Code)) +
  geom_bar(stat="identity",fill="#56B4E9") +
  facet_wrap(~Code,nrow=4,scales="free_y") +
  labs(y="Instance rate (per 1,000)")+
  scale_x_date(date_breaks = "2 months",expand=c(0,0))  +
  theme(axis.text.x = element_text(angle = -90,vjust = 0))
print("national fig07 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig07_ctv3nattrends.svg"),width = 30, height = 30, dpi=300,units ="cm")
print("national fig07 saved")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 

ggplot(data=df_summary_long %>% filter(substr(Code,1,nchar(myprefix))==myprefix),aes(x=month,y=rate_per_1000,color=Code)) +
  geom_line()+
  scale_x_date(date_breaks = "2 months",expand=c(0,0))+
  labs(y="Instance rate (per 1,000)")+
  theme(axis.text.x = element_text(angle = -90,vjust = 0))
print("national fig08 created")

ggsave(paste0(here::here("output","plots"),"/sc03_fig08_ctv3nattrends.svg"),width = 40, height = 20, dpi=300,units ="cm")
print("national fig08 saved")
# Disclosiveness: plot of national monthly tally of clinical code occurrence, not deemed disclosive. 


## close log connection
sink()

