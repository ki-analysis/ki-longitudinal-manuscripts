



rm(list = ls())
source(paste0(here::here(), "/0-config.R"))
source(paste0(here::here(),"/0-project-functions/0_descriptive_epi_wast_functions.R"))
source(paste0(here::here(),"/0-project-functions/0_descriptive_epi_co_functions.R"))

load(paste0(ghapdata_dir, "Underweight_inc_data.RData"))

#Subset to monthly
d <- d %>% filter(measurefreq == "monthly")



length(unique(paste0(d$studyid,d$country)))
d %>% ungroup() %>% distinct(region, studyid, country) %>% group_by(region) %>% summarise(N=n())

#Overall absolute counts
df <- d %>% filter(agedays < 24 *30.4167) %>%
            mutate(uwt = 1*(waz < -2),
                   sevuwt = 1*(waz < -3))
table(df$uwt)
prop.table(table(df$uwt))*100
table(df$sevuwt)
prop.table(table(df$sevuwt))*100


#Number uwted by 3 months
df2 <- df %>% filter(agedays < 3 *30.4167) %>% group_by(studyid, country, subjid) %>% mutate(anyuwt = 1*(min(waz) < -2)) %>% slice(1)
table(df2$anyuwt)
prop.table(table(df2$anyuwt))


#Underweight recovery
df2 <- d %>% group_by(studyid, country, subjid) %>% mutate(uwt=max(wast_inc), rec=max(wast_rec)) %>% 
              filter(uwt==1)
table(df2$rec)
prop.table(table(df2$rec))


#Severe underweight recovery
df2 <- d %>% group_by(studyid, country, subjid) %>% mutate(uwt=max(sevwast_inc), rec=max(sevwast_rec)) %>% 
  filter(uwt==1)
table(df2$rec)
prop.table(table(df2$rec))



#Prevalence
d <- calc.prev.agecat(d)
prev.data <- summary.prev.whz(d)
prev.region <- d %>% group_by(region) %>% do(summary.prev.whz(.)$prev.res)
prev.country <- d %>% group_by(region, country) %>% do(summary.prev.whz(.)$prev.res) 
prev.cohort <-
  prev.data$prev.cohort %>% subset(., select = c(cohort, region, agecat, nmeas,  prev,  ci.lb,  ci.ub)) %>%
  rename(est = prev,  lb = ci.lb,  ub = ci.ub)

prev <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", prev.data$prev.res),
  data.frame(cohort = "pooled", prev.country),
  data.frame(cohort = "pooled", prev.region),
  prev.cohort
)

#Severe underweight prevalence
sev.prev.data <- summary.prev.whz(d, severe.wasted = T)
sev.prev.region <- d %>% group_by(region) %>% do(summary.prev.whz(., severe.wasted = T)$prev.res)
sev.prev.country <- d %>% group_by(region, country) %>% do(summary.prev.whz(., severe.wasted = T)$prev.res) 

sev.prev.cohort <-
  sev.prev.data$prev.cohort %>% subset(., select = c(cohort, region, agecat, nmeas,  prev,  ci.lb,  ci.ub)) %>%
  rename(est = prev,  lb = ci.lb,  ub = ci.ub)

sev.prev <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", sev.prev.data$prev.res),
  data.frame(cohort = "pooled", sev.prev.country),
  data.frame(cohort = "pooled", sev.prev.region),
  sev.prev.cohort
)

#mean waz
waz.data <- summary.waz(d)
waz.region <- d %>% group_by(region) %>% do(summary.waz(.)$waz.res)
waz.country <- d %>% group_by(region, country) %>% do(summary.waz(.)$waz.res) 
waz.cohort <-
  waz.data$waz.cohort %>% subset(., select = c(cohort, region, agecat, nmeas,  meanwaz,  ci.lb,  ci.ub)) %>%
  rename(est = meanwaz,  lb = ci.lb,  ub = ci.ub)

waz <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", waz.data$waz.res),
  data.frame(cohort = "pooled", waz.country),
  data.frame(cohort = "pooled", waz.region),
  waz.cohort
)


#monthly mean waz
d <- calc.monthly.agecat(d)
#get range of N obs for figure caption
d %>% filter(!is.na(agecat)) %>% group_by(agecat) %>% summarize(N=n()) %>% ungroup() %>% summarise(min(N), max(N))
d %>% filter(!is.na(agecat)) %>% group_by(agecat, region) %>% summarize(N=n()) %>% group_by(region) %>% summarise(min(N), max(N))

monthly.data <- summary.waz(d)
monthly.region <- d %>% group_by(region) %>% do(summary.waz(.)$waz.res)
monthly.country <- d %>% group_by(region, country) %>% do(summary.waz(.)$waz.res) 
monthly.cohort <-
  monthly.data$waz.cohort %>% subset(., select = c(cohort, region, agecat, nmeas,  meanwaz,  ci.lb,  ci.ub)) %>%
  rename(est = meanwaz,  lb = ci.lb,  ub = ci.ub)

monthly.waz <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", monthly.data$waz.res),
  data.frame(cohort = "pooled", monthly.country),
  data.frame(cohort = "pooled", monthly.region),
  monthly.cohort
)

#Get monthly waz quantiles
quantile_d <- d %>% group_by(agecat, region) %>%
  mutate(N=n(),
         fifth_perc = quantile(waz, probs = c(0.05))[[1]],
         fiftieth_perc = quantile(waz, probs = c(0.5))[[1]],
         ninetyfifth_perc = quantile(waz, probs = c(0.95))[[1]]) %>%
  select(agecat, region, fifth_perc, fiftieth_perc, ninetyfifth_perc, N)
quantile_d_country <- d %>% group_by(agecat, country) %>%
  mutate(N=n(),
         fifth_perc = quantile(waz, probs = c(0.05))[[1]],
         fiftieth_perc = quantile(waz, probs = c(0.5))[[1]],
         ninetyfifth_perc = quantile(waz, probs = c(0.95))[[1]]) %>%
  select(agecat, region, fifth_perc, fiftieth_perc, ninetyfifth_perc, N)
quantile_d_overall <- d %>% group_by(agecat) %>%
  mutate(N=n(),
        fifth_perc = quantile(waz, probs = c(0.05))[[1]],
         fiftieth_perc = quantile(waz, probs = c(0.5))[[1]],
         ninetyfifth_perc = quantile(waz, probs = c(0.95))[[1]]) %>%
  select(agecat, fifth_perc, fiftieth_perc, ninetyfifth_perc, N)

saveRDS(list(quantile_d=quantile_d, 
             quantile_d_country=quantile_d_country, 
             quantile_d_overall=quantile_d_overall), 
        file = paste0(BV_dir,"/results/quantile_data_underweight.RDS"))



#Cumulative inc 6 month intervals
d6 <- calc.ci.agecat(d, range = 6)

#RE pooled estimates
ci.data6 <- summary.wast.ci(d6, age.range=6)
ci.region6 <- d6 %>% group_by(region) %>% do(summary.wast.ci(., age.range=6)$ci.res)

ci.data6$ci.res
ci.region6

#Cumulative inc 3 month intervals
d3 <- calc.ci.agecat(d, range = 3)
length(unique(paste0(d3$studyid, d3$subjid)))

#Calculate the raw  proportion of ever-uwted children who became uwted at each age
d3_raw <- d3 %>% group_by(studyid, subjid) %>% filter(!is.na(agecat)) %>%
  mutate(minwaz=min(waz)) %>% filter(minwaz < -2) %>% arrange(agedays) %>% mutate(sum_inc=cumsum(wast_inc))
length(unique(paste0(d3_raw$studyid, d3_raw$subjid)))
d3_raw_first_inc <- d3_raw %>% filter(sum_inc==1) %>% slice(1)
dim(d3_raw_first_inc)
table(d3_raw_first_inc$agecat)
prop.table(table(d3_raw_first_inc$agecat)) * 100

#RE pooled estimates
ci.data3 <- summary.wast.ci(d3, age.range=3)
ci.region3 <- d3 %>% group_by(region) %>% do(summary.wast.ci(., age.range=3)$ci.res)
ci.country3 <- d3 %>% group_by(region, country) %>% do(summary.wast.ci(., age.range=3)$ci.res) 
ci.cohort3 <-
  ci.data3$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ci_3 <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ci.data3$ci.res),
  data.frame(cohort = "pooled", ci.country3),
  data.frame(cohort = "pooled", ci.region3),
  ci.cohort3
) 

#0-24 cumulative inc
df<- d3 %>% mutate(agecat="0-24 months")
evs = df %>%
  filter(agedays < 731) %>%
  group_by(studyid,country,subjid) %>%
  arrange(studyid,subjid) %>%
  mutate(minwaz=min(waz, na.rm=T)) %>%
  mutate(ever_uwted=ifelse(minwaz< -2,1,0),
         agecat=factor(agecat))
cuminc.data= evs%>%
  group_by(studyid,country,agecat) %>%
  summarise(
    nchild=length(unique(subjid)),
    nstudy=length(unique(studyid)),
    ncases=sum(ever_uwted),
    N=sum(length(ever_uwted))) %>%
  filter(N>=50)
ci.data024 <-  lapply(levels(cuminc.data$agecat),function(x)
  fit.rma(data=cuminc.data,ni="N", xi="ncases",age=x,measure="PLO",nlab=" measurements", method="REML"))



#Cumulative inc 3 month - birth as seperate category
d3_nobirth <- calc.ci.agecat(d, range = 3, birth="no")

ci.data3_nobirth <- summary.wast.ci(d3_nobirth, age.range=3, birthstrat = T)
ci.region3_nobirth <- d3_nobirth %>% group_by(region) %>% do(summary.wast.ci(., age.range=3, birthstrat = T)$ci.res)
ci.country3_nobirth <- d3_nobirth %>% group_by(region, country) %>% do(summary.wast.ci(., age.range=3, birthstrat = T)$ci.res) 
ci.cohort3_nobirth <-
  ci.data3_nobirth$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ci_3_nobirth <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ci.data3_nobirth$ci.res),
  data.frame(cohort = "pooled", ci.country3_nobirth),
  data.frame(cohort = "pooled", ci.region3_nobirth),
  ci.cohort3
) 

ci.data3$ci.res
ci.data3_nobirth$ci.res


#Incidence proportions 3 month intervals
ip.data3 <- summary.incprop(d3)
ip.region3 <- d3 %>% group_by(region) %>% do(summary.incprop(.)$ci.res)
ip.country3 <- d3 %>% group_by(region, country) %>% do(summary.incprop(.)$ci.res) 
ip.cohort3 <-
  ip.data3$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ip_3 <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ip.data3$ci.res),
  data.frame(cohort = "pooled", ip.country3),
  data.frame(cohort = "pooled", ip.region3),
  ip.cohort3
)

#Incidence proportions 3 month intervals - no birth
ip.data3_nobirth <- summary.incprop(d3_nobirth)
ip.region3_nobirth <- d3_nobirth %>% group_by(region) %>% do(summary.incprop(.)$ci.res)
ip.country3_nobirth <- d3_nobirth %>% group_by(region, country) %>% do(summary.incprop(.)$ci.res) 
ip.cohort3_nobirth <-
  ip.data3_nobirth$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ip_3_nobirth <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ip.data3_nobirth$ci.res),
  data.frame(cohort = "pooled", ip.country3_nobirth),
  data.frame(cohort = "pooled", ip.region3_nobirth),
  ip.cohort3_nobirth
)



#Cumulative inc of severe underweight
d <- calc.ci.agecat(d, range = 6)
agelst = list("0-6 months", "6-12 months", "12-18 months", "18-24 months")
sev.ci.data <- summary.wast.ci(d=d,  severe.wasted = T, age.range=6)
sev.ci.region <- d %>% group_by(region) %>% do(summary.wast.ci(., severe.wasted = T, age.range=6)$ci.res)
sev.ci.country <- d %>% group_by(region, country) %>% do(summary.wast.ci(., severe.wasted = T, age.range=6)$ci.res) 
sev.ci.cohort <-
  sev.ci.data$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

sev.ci <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", sev.ci.data$ci.res),
  data.frame(cohort = "pooled", sev.ci.country),
  data.frame(cohort = "pooled", sev.ci.region),
  sev.ci.cohort
)





#Incidence rate
ir.data <- summary.ir(d)
ir.region <- d %>% group_by(region) %>% do(summary.ir(.)$ir.res)
ir.country <- d %>% group_by(region, country) %>% do(summary.ir(.)$ir.res) 
ir.cohort <-
  ir.data$ir.cohort %>% subset(., select = c(studyid, country, cohort, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ir <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ir.data$ir.res),
  data.frame(cohort = "pooled", ir.country),
  data.frame(cohort = "pooled", ir.region),
  ir.cohort
)



#Incidence rate - severe underweight
sev.ir.data <- summary.ir(d, sev.wasting = T)
sev.ir.region <- d %>% group_by(region) %>% do(summary.ir(., sev.wasting = T)$ir.res)
sev.ir.country <- d %>% group_by(region, country) %>% do(summary.ir(., sev.wasting = T)$ir.res) 
sev.ir.cohort <-
  sev.ir.data$ir.cohort %>% subset(., select = c(studyid, country,cohort, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

sev.ir <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", sev.ir.data$ir.res),
  data.frame(cohort = "pooled", sev.ir.country),
  data.frame(cohort = "pooled", sev.ir.region),
  sev.ir.cohort
)





#Incidence rate - 3 month intervals
d3 <- calc.ci.agecat(d, range = 3)
agelst3 = list(
  "0-3 months",
  "3-6 months",
  "6-9 months",
  "9-12 months",
  "12-15 months",
  "15-18 months",
  "18-21 months",
  "21-24 months"
)
ir.data <- summary.ir(d3)
ir.region <- d3 %>% group_by(region) %>% do(summary.ir(.)$ir.res)
ir.country <- d3 %>% group_by(region, country) %>% do(summary.ir(.)$ir.res) 
ir.cohort <-
  ir.data$ir.cohort %>% subset(., select = c(studyid, country,cohort, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

ir3 <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", ir.data$ir.res),
  data.frame(cohort = "pooled", ir.country),
  data.frame(cohort = "pooled", ir.region),
  ir.cohort
)





#Duration
df <- d %>% group_by(studyid, subjid, episode_id) %>% slice(1) %>% filter(!is.na(wasting_duration)) %>% filter(agedays < 30.6417 * 24)
median(df$wasting_duration, na.rm=T)
#Quantile CI's'
sort(df$wasting_duration)[qbinom(c(.025,.975), length(df$wasting_duration), 0.5)]

#Recovery within 30, 60, 90 days
#Overall
df <- d %>% filter(agedays < 30.4617 * 24)
df$agecat <- "0-24 months"
overall.rec.data30 <- summary.rec60(df, length = 30)
overall.rec.data60 <- summary.rec60(df, length = 60)
overall.rec.data90 <- summary.rec60(df, length = 90)
overall.rec.data30$ci.res
overall.rec.data60$ci.res
overall.rec.data90$ci.res

#Age-strat
d <- calc.ci.agecat(d, range = 6)
rec.data30 <- summary.rec60( d, length = 30)
rec.data60 <- summary.rec60( d, length = 60)
rec.data90 <- summary.rec60( d, length = 90)
rec30.region <- d %>% group_by(region) %>% do(summary.rec60( ., length = 30)$ci.res)
rec60.region <- d %>% group_by(region) %>% do(summary.rec60( ., length = 60)$ci.res)
rec90.region <- d %>% group_by(region) %>% do(summary.rec60( ., length = 90)$ci.res)
rec30.country <- d %>% group_by(region, country) %>% do(summary.rec60( ., length = 30)$ci.res) 
rec60.country <- d %>% group_by(region, country) %>% do(summary.rec60( ., length = 60)$ci.res) 
rec90.country <- d %>% group_by(region, country) %>% do(summary.rec60( ., length = 90)$ci.res) 

rec30.cohort <-
  rec.data30$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)
rec60.cohort <-
  rec.data60$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)
rec90.cohort <-
  rec.data90$ci.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

rec30<- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", rec.data30$ci.res),
  data.frame(cohort = "pooled", rec30.country),
  data.frame(cohort = "pooled", rec30.region),
  rec30.cohort
)
rec60<- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", rec.data60$ci.res),
  data.frame(cohort = "pooled", rec60.country),
  data.frame(cohort = "pooled", rec60.region),
  rec60.cohort
)
rec90<- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", rec.data90$ci.res),
  data.frame(cohort = "pooled", rec90.country),
  data.frame(cohort = "pooled", rec90.region),
  rec90.cohort
)

#Persistant underweight
persuwt.data <- summary.perswast(d)
persuwt.region <- d %>% group_by(region) %>% do(summary.perswast(.)$pers.res)
persuwt.country <- d %>% group_by(region, country) %>% do(summary.perswast(.)$pers.res) 
persuwt.cohort <-
  persuwt.data$pers.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

persuwt <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", persuwt.data$pers.res),
  data.frame(cohort = "pooled", persuwt.country),
  data.frame(cohort = "pooled", persuwt.region),
  persuwt.cohort
)

#0-24 month persistent underweight
df<- d %>% mutate(agecat="0-24 months")
persuwt.data <- summary.perswast(df)
persuwt.region <- df %>% group_by(region) %>% do(summary.perswast(.)$pers.res)
persuwt.country <- df %>% group_by(region, country) %>% do(summary.perswast(.)$pers.res) 
persuwt.cohort <-
  persuwt.data$pers.cohort %>% subset(., select = c(cohort, region, agecat,  yi,  ci.lb,  ci.ub)) %>%
  rename(est = yi,  lb = ci.lb,  ub = ci.ub)

persuwt024 <- bind_rows(
  data.frame(cohort = "pooled", region = "Overall", persuwt.data$pers.res),
  data.frame(cohort = "pooled", persuwt.country),
  data.frame(cohort = "pooled", persuwt.region),
  persuwt.cohort
)
save(persuwt024, file = paste0(BV_dir,"/results/persistent_underweight024.Rdata"))








underweight_desc_data <- bind_rows(
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Prevalence", prev),
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="yes", measure= "Prevalence", sev.prev),
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Mean WLZ",  waz),
  data.frame(disease = "Underweight", age_range="1 month",   birth="yes", severe="no", measure= "Mean WLZ",  monthly.waz),
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Cumulative incidence", ci_3),
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Incidence_proportion", ip_3),
  data.frame(disease = "Underweight", age_range="3 months",   birth="strat", severe="no", measure= "Incidence_proportion", ip_3_nobirth),
  data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="yes", measure= "Cumulative incidence",  sev.ci),
  data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="no", measure= "Incidence rate",  ir),
  data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Incidence rate",  ir3),
  data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="yes", measure= "Incidence rate",  sev.ir),
  data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="no", measure= "Persistent underweight", persuwt),
  data.frame(disease = "Underweight", age_range="30 days",   birth="yes", severe="no", measure= "Recovery", rec30),
  data.frame(disease = "Underweight", age_range="60 days",   birth="yes", severe="no", measure= "Recovery", rec60),
  data.frame(disease = "Underweight", age_range="90 days",   birth="yes", severe="no", measure= "Recovery", rec90)#,
  # data.frame(disease = "Underweight", age_range="3 months",   birth="yes", severe="no", measure= "Cumulative incidence - no recovery", ci_3_noRec),
  # data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="yes", measure= "Cumulative incidence - no recovery", sev.ci_noRec),
  # data.frame(disease = "Underweight", age_range="6 months",   birth="yes", severe="no", measure= "Incidence rate - no recovery", ir_noRec)
)

underweight_desc_data <- droplevels(underweight_desc_data)


underweight_desc_data <- underweight_desc_data %>% subset(., select = -c(se, nmeas.f,  ptest.f, pt.f))

unique(underweight_desc_data$agecat)
underweight_desc_data$agecat <- factor(underweight_desc_data$agecat, levels=unique(underweight_desc_data$agecat))

unique(underweight_desc_data$region)
underweight_desc_data$region[underweight_desc_data$region=="Asia"] <- "South Asia"
underweight_desc_data$region <- factor(underweight_desc_data$region, levels=c("Overall", "Africa", "Latin America", "South Asia"))

#Add in variable for level of pooling
underweight_desc_data <- underweight_desc_data %>% 
  mutate(pooling = case_when(
    cohort != "pooled" ~ "no pooling",
    cohort == "pooled" & !is.na(country) ~ "country",
    region != "Overall" ~ "regional",
    region == "Overall" ~ "overall"
  ))

table(underweight_desc_data$pooling)
table(is.na(underweight_desc_data$pooling))


#clean country names
underweight_desc_data$country[underweight_desc_data$country=="TANZANIA, UNITED REPUBLIC OF"] <- "TANZANIA"
underweight_desc_data$country <- stringr::str_to_title(underweight_desc_data$country)


        

saveRDS(underweight_desc_data, file = paste0(BV_dir,"/results/underweight_desc_data.RDS"))



