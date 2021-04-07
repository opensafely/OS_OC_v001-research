# ##==============================================================================
# Analysis filename:			0a-snomedcheck
# 
## ==============================================================================

## open log connection to file
sink(here::here("logs", "log-0a-snomedcheck.txt"))
library(skimr)
# create directory for saving tables, if not existent
if (!dir.exists(here::here("output", "tables"))){
  dir.create(here::here("output", "tables"))
}

## import and pre-process cohort data
df_input <- read_csv(
  here::here("output", "input_checksnomed.csv"))

View(head(df_input))

print(df_input %>% select_if(is.numeric) %>% summarise_all(~sum(.,na.rm=T)))

print(skim(df_input))

print(summary(df_input))

df_summary <- df_input %>% select_if(is.numeric) %>% summarise_all(~sum(.,na.rm=T))

write.csv(df_summary,paste0(here::here("output","tables"),"/sc0a_snomedcheck_tallies.csv"))


## close log connection
sink()


