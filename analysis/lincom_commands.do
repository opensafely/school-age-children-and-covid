



cd  `c(pwd)' /*sets working directory to workspace folder*/
cap log close 
log using time_interactions_lincom, replace

forvalues x=0/1 {
foreach outcome in  covid_death covid_icu   {

estimates use  ./output/an_interaction_cox_models_`outcome'_kids_cat3_cat_time_MAINFULLYADJMODEL_agespline_bmicat_noeth_ageband_`x'.ster
di _n "`outcome' " _n "****************"
di "`outcome'" _n "****************"
lincom 2.kids_cat3 + 1.cat_time#2.kids_cat3, eform
}
}

log close


estimates use  C:\Users\ENCDHFOR\Documents\GitHub\school-age-children-and-covid\analysis\output/an_interaction_cox_models_covid_tpp_prob_kids_cat3_weeks_MAINFULLYADJMODEL_agespline_bmicat_noeth_ageband_1.ster
lincom 1.kids_cat3 + 1.weeks#1.kids_cat3
return list

