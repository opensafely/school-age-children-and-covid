



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


estimates use  C:/Users/ENCDHFOR/Documents/GitHub/school-age-children-and-covid/analysis/output/an_sense_covid_tpp_prob_multiple_imputation_ageband_0.ster
local hr = exp( el(e(b_mi),1,2) )
			di `hr'
			local lb = exp( el(e(b_mi),1,2)  - 1.96*  sqrt(el(e(V_mi),2,2))  )
			di `lb'
			local ub = exp( el(e(b_mi),1,2)  + 1.96*  sqrt(el(e(V_mi),2,2))  )

