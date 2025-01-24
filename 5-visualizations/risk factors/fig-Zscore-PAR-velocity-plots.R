



rm(list=ls())
source(paste0(here::here(), "/0-config.R"))
source(paste0(here::here(), "/0-project-functions/0_clean_study_data_functions.R"))
library(gtable)
require(cowplot)



#Load data
par <- readRDS(paste0(BV_dir,"/results/rf results/pooled_Zscore_PAR_results.rds"))

dim(par)

unique(par$intervention_level)
unique(par$intervention_variable)
par$intervention_level <- as.character(par$intervention_level)
par$intervention_level[par$intervention_level=="Full or late term"] <- "Full/late term"
par$intervention_level[par$intervention_level=="(0%, 5%]"] <- "(0%,5%]"
par$intervention_level[par$intervention_level=="No"] <- "None"
par$intervention_level[par$intervention_level=="Yes"] <- "All"
par$intervention_level[par$intervention_level=="1" & par$intervention_variable %in% c("brthmon","month")] <- "Jan."
par$intervention_level[par$intervention_level=="0" & par$intervention_variable %in% c("single")] <- "Partnered"
par$intervention_level[par$intervention_level=="1" & par$intervention_variable %in% c("parity")] <- "Firstborn"
par$intervention_level[par$intervention_level=="None" & par$intervention_variable %in% c("vagbrth")] <- "C-section"
par$intervention_level[par$intervention_level=="None" & par$intervention_variable %in% c("hdlvry")] <- "No"

par$RFlabel[par$RFlabel=="Diarrhea <24 mo.  (% days"] <- "Diarrhea <24mo. (% days)"
par$RFlabel[par$RFlabel=="Diarrhea <6 mo. (% days)"] <- "Diarrhea <6mo. (% days)"
par$RFlabel[par$RFlabel=="Gestational age at birth"] <- "Gestational age"

unique(par$outcome_variable)
par <- par %>% filter(outcome_variable %in% c("y_rate_haz", "y_rate_waz", "y_rate_len","y_rate_wtkg"))
par$outcome_variable <- gsub("y_rate_haz", "LAZ velocity", par$outcome_variable)
par$outcome_variable <- gsub("y_rate_waz", "WAZ velocity", par$outcome_variable)
par$outcome_variable <- gsub("y_rate_len", "length velocity", par$outcome_variable)
par$outcome_variable <- gsub("y_rate_wtkg", "weight velocity", par$outcome_variable)

par <- par %>% subset(., select = c(outcome_variable, agecat, region, intervention_variable, intervention_level, PAR, CI1, CI2, RFlabel, RFlabel_ref, n_cell, n)) %>% 
  filter(!is.na(PAR)) %>% mutate(measure="PAR")  %>%
  mutate(RFlabel_ref = paste0(RFlabel," shifted to ", intervention_level))

par_agestrat <- par %>% filter(agecat %in% c(
  "0-3 months", "3-6 months" , "6-9 months","9-12 months", 
  "12-15 months", "15-18 months", "18-21 months", "21-24 months"  ), region=="Pooled", 
  outcome_variable %in% c("LAZ velocity", "WAZ velocity", "length velocity", "weight velocity"), !is.na(PAR))  

table(par_agestrat$outcome_variable)
table(par_agestrat$intervention_variable)

#######################
# Reviewer response plot
#######################

df <- par %>% filter(intervention_variable %in% c("mbmi", "mhtcm","mwtkg"), region=="Pooled") 
    

rflevels = unique(df$RFlabel_ref)
df$RFlabel_ref=factor(df$RFlabel_ref, levels=rflevels)
unique(df$agecat)
df$agecat=factor(df$agecat, levels=rev(c("0-3 months","3-6 months","6-9 months",
                                          "9-12 months","12-15 months", "15-18 months",
                                          "18-21 months", "21-24 months")))
df <- df %>% arrange(outcome_variable, intervention_variable, agecat)


plot <-  ggplot(df, aes(x=agecat)) + 
  geom_point(aes(y=-PAR,  color=measure, shape = measure), size = 4) +
  geom_errorbar(aes(ymin=-CI1, ymax=-CI2, color=measure),  alpha=0.8) +
  scale_colour_manual(values=c("#7F7F7F")) +
  geom_hline(yintercept = 0) +
  coord_flip() +
  facet_wrap(RFlabel_ref~outcome_variable, scales="free") +
  theme(strip.background = element_blank(),
        legend.position="right",
        axis.text.y = element_text(hjust = 1),
        strip.text.x = element_text(size=12),
        axis.text.x = element_text(size=12), 
        plot.margin = unit(c(15, 5, 5, 5), "pt")) +
  guides(color=FALSE, shape=FALSE)
plot

res <-df %>% filter(CI1<0 & CI2<0|CI1>0 & CI2>0) %>% mutate(PAR=round(PAR*-1,3),CI1=round(CI1*-1,3),CI2=round(CI2*-1,3)) %>%
  subset(., select=c(outcome_variable,agecat, intervention_variable, PAR, CI1, CI2)) %>%
  arrange(intervention_variable,outcome_variable,rev(agecat))


#######################
# Age stratified plots
#######################

outcome="WAZ velocity"
age="0-3 months"
#data <- par_agestrat %>% filter(outcome_variable == outcome) %>% arrange(-PAR) 


plot_age = function(outcome, age){
  data <- par_agestrat %>% filter(outcome_variable == outcome, agecat == age) %>% arrange(-PAR) 
  
  rflevels = unique(data$RFlabel_ref)
  data$RFlabel_ref=factor(data$RFlabel_ref, levels=rflevels)
  
  
  lb = -max(par_agestrat %>% filter(outcome_variable == outcome) %>% select(CI2))
  ub = -min(par_agestrat %>% filter(outcome_variable == outcome) %>% select(CI1))
  
  plot <-  ggplot(data, aes(x=RFlabel_ref)) + 
    geom_point(aes(y=-PAR,  color=measure, shape = measure), size = 4) +
    geom_errorbar(aes(ymin=-CI1, ymax=-CI2, color=measure),  alpha=0.8) +
    coord_flip(ylim=c(lb, ub)) +
    scale_colour_manual(values=c("#7F7F7F")) +
    labs(x = "", y = paste0("Attributable difference in\n", outcome)) +
    geom_hline(yintercept = 0) +
    ggtitle(paste0(age, ", Pooled")) + 
    theme(strip.background = element_blank(),
          legend.position="right",
          axis.text.y = element_text(hjust = 1),
          strip.text.x = element_text(size=12),
          axis.text.x = element_text(size=12), 
          plot.margin = unit(c(15, 5, 5, 5), "pt")) +
    guides(color=FALSE, shape=FALSE)
  
  return (plot)
}

### Plot LAZ, stratified by age
plot_laz_3 = plot_age("LAZ velocity", "0-3 months")
plot_laz_6 = plot_age("LAZ velocity", "3-6 months")
plot_laz_9 = plot_age("LAZ velocity", "6-9 months")
plot_laz_12 = plot_age("LAZ velocity", "9-12 months")
plot_laz_15 = plot_age("LAZ velocity", "12-15 months")
plot_laz_18 = plot_age("LAZ velocity", "15-18 months")
plot_laz_21 = plot_age("LAZ velocity", "18-21 months")
plot_laz_24 = plot_age("LAZ velocity", "21-24 months")




plot_laz_age = grid.arrange(plot_laz_3, 
                            plot_laz_6, 
                            plot_laz_9, 
                            plot_laz_12,
                            plot_laz_15, 
                            plot_laz_18, 
                            plot_laz_21, 
                            plot_laz_24, ncol = 2, nrow = 4,
                            top = textGrob("Attributable difference - LAZ velocity, stratified by age",gp=gpar(fontsize=26,font=2)))

ggsave(plot_laz_age, file=paste0(BV_dir, "/figures/manuscript-figure-composites/risk-factor/extended-data/fig-laz-vel-PAR.png"), height=36, width=15)






### Plot WAZ, stratified by age
plot_waz_3 = plot_age("WAZ velocity", "0-3 months")
plot_waz_6 = plot_age("WAZ velocity", "3-6 months")
plot_waz_9 = plot_age("WAZ velocity", "6-9 months")
plot_waz_12 = plot_age("WAZ velocity", "9-12 months")
plot_waz_15 = plot_age("WAZ velocity", "12-15 months")
plot_waz_18 = plot_age("WAZ velocity", "15-18 months")
plot_waz_21 = plot_age("WAZ velocity", "18-21 months")
plot_waz_24 = plot_age("WAZ velocity", "21-24 months")




plot_waz_age = grid.arrange(plot_waz_3, 
                            plot_waz_6, 
                            plot_waz_9, 
                            plot_waz_12,
                            plot_waz_15, 
                            plot_waz_18, 
                            plot_waz_21, 
                            plot_waz_24, ncol = 2, nrow = 4,
                            top = textGrob("Attributable difference - WAZ velocity, stratified by age",gp=gpar(fontsize=26,font=2)))

ggsave(plot_waz_age, file=paste0(BV_dir, "/figures/manuscript-figure-composites/risk-factor/extended-data/fig-waz-vel-PAR.png"), height=36, width=15)




### Plot length, stratified by age
plot_length_3 = plot_age("length velocity", "0-3 months")
plot_length_6 = plot_age("length velocity", "3-6 months")
plot_length_9 = plot_age("length velocity", "6-9 months")
plot_length_12 = plot_age("length velocity", "9-12 months")
plot_length_15 = plot_age("length velocity", "12-15 months")
plot_length_18 = plot_age("length velocity", "15-18 months")
plot_length_21 = plot_age("length velocity", "18-21 months")
plot_length_24 = plot_age("length velocity", "21-24 months")




plot_length_age = grid.arrange(plot_length_3, 
                            plot_length_6, 
                            plot_length_9, 
                            plot_length_12,
                            plot_length_15, 
                            plot_length_18, 
                            plot_length_21, 
                            plot_length_24, ncol = 2, nrow = 4,
                            top = textGrob("Attributable difference - length velocity, stratified by age",gp=gpar(fontsize=26,font=2)))

ggsave(plot_length_age, file=paste0(BV_dir, "/figures/manuscript-figure-composites/risk-factor/extended-data/fig-length-vel-PAR.png"), height=36, width=15)



### Plot weight, stratified by age
plot_weight_3 = plot_age("weight velocity", "0-3 months")
plot_weight_6 = plot_age("weight velocity", "3-6 months")
plot_weight_9 = plot_age("weight velocity", "6-9 months")
plot_weight_12 = plot_age("weight velocity", "9-12 months")
plot_weight_15 = plot_age("weight velocity", "12-15 months")
plot_weight_18 = plot_age("weight velocity", "15-18 months")
plot_weight_21 = plot_age("weight velocity", "18-21 months")
plot_weight_24 = plot_age("weight velocity", "21-24 months")




plot_weight_age = grid.arrange(plot_weight_3, 
                            plot_weight_6, 
                            plot_weight_9, 
                            plot_weight_12,
                            plot_weight_15, 
                            plot_weight_18, 
                            plot_weight_21, 
                            plot_weight_24, ncol = 2, nrow = 4,
                            top = textGrob("Attributable difference - weight velocity, stratified by age",gp=gpar(fontsize=26,font=2)))

ggsave(plot_weight_age, file=paste0(BV_dir, "/figures/manuscript-figure-composites/risk-factor/extended-data/fig-weight-vel-PAR.png"), height=36, width=15)



