*Do file: 09_an_agesplinevisualisation
*************************************************************************
*Purpose: Make figure of agespline effects
*
*Requires: final analysis dataset (analysis_dataset.dta)
*
*Coding: HFORBES, based on file from Krishnan Bhaskaran
*
*Date drafted: 30th June 2020
*************************************************************************



local outcome `1' 


use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_0.dta", clear

cap estimates use ./output/an_multivariate_cox_models_`outcome'_kids_cat3_MAINFULLYADJMODEL_noeth_ageband_0

if _rc==0 {

	bysort age: keep if _n==1

	for var male htdiag_or_highbp chronic_respiratory_disease ///
	chronic_cardiac_disease /// 
	chronic_liver_disease stroke_dementia other_neuro other_transplant ///
	asplenia ra_sle_psoriasis other_immuno esrd: replace X = 0 

	for var obese4cat smoke_nomiss imd asthma diabcat cancer_exhaem_cat cancer_haem_cat  ///
	reduced_kidney_function_cat tot_adults_hh: replace X = 1 
	
	predict xb, xb
	summ xb if age==45
	gen xb_c = xb-r(mean)
	gen hrcf45 = exp(xb_c)
	*line xb_c age, sort xtitle(Age in years) ytitle("Log hazard ratio (reference age 55 years)") yline(0, lp(dash))
	
	line hrcf45 age, sort xtitle(Age in years) ytitle("Hazard ratio compared to age 45 years (log scale)") yscale(log) ylab( 0.01 0.1 1 10 100 20) yline(0, lp(dash))

	graph export ./output/an_agesplinevisualisation_`outcome'_ageband_0.svg, as(svg) replace

}

use "$tempdir/cr_create_analysis_dataset_STSET_`outcome'_ageband_1.dta", clear

cap estimates use ./output/an_multivariate_cox_models_`outcome'_kids_cat3_MAINFULLYADJMODEL_noeth_ageband_1

if _rc==0 {

	bysort age: keep if _n==1

	for var male htdiag_or_highbp chronic_respiratory_disease ///
	chronic_cardiac_disease /// 
	chronic_liver_disease stroke_dementia other_neuro other_transplant ///
	asplenia ra_sle_psoriasis other_immuno esrd: replace X = 0 

	for var obese4cat smoke_nomiss imd asthma diabcat cancer_exhaem_cat cancer_haem_cat  ///
	reduced_kidney_function_cat tot_adults_hh: replace X = 1 
	
	predict xb, xb
	summ xb if age==75
	gen xb_c = xb-r(mean)
	gen hrcf75 = exp(xb_c)
	*line xb_c age, sort xtitle(Age in years) ytitle("Log hazard ratio (reference age 55 years)") yline(0, lp(dash))
	
	line hrcf75 age, sort xtitle(Age in years) ytitle("Hazard ratio compared to age 75 years (log scale)") yscale(log) ylab( 0.01 0.1 1 10 100 20) yline(0, lp(dash))

	graph export ./output/an_agesplinevisualisation_`outcome'_ageband_1.svg, as(svg) replace

}

