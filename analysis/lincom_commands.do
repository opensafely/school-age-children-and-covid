



cd  `c(pwd)' /*sets working directory to workspace folder*/
cap log close 
log using time_interactions_lincom, replace

forvalues x=0/1 {
foreach outcome in covid_death_icu  covid_death covid_icu   {

estimates use  ./analysis/output/an_interaction_cox_models_`outcome'_kids_cat3_cat_time_MAINFULLYADJMODEL_agespline_bmicat_noeth_ageband_`x'.ster
di _n "`outcome' " _n "****************"
lincom 1.kids_cat3 + 1.cat_time#1.kids_cat3, eform
di "`outcome'" _n "****************"
lincom 2.kids_cat3 + 1.cat_time#2.kids_cat3, eform
}
}

log close



