


*Run each sequentially adjusted model on those with complete ethnicity data

global comordidadjlist  i.htdiag_or_highbp				///
			i.chronic_respiratory_disease 	///
			i.asthma						///
			i.chronic_cardiac_disease 		///
			i.diabcat						///
			i.cancer_exhaem_cat	 			///
			i.cancer_haem_cat  				///
			i.chronic_liver_disease 		///
			i.stroke_dementia		 		///
			i.other_neuro					///
			i.reduced_kidney_function_cat	///
			i.esrd							///
			i.other_transplant 				///
			i.asplenia 						///
			i.ra_sle_psoriasis  			///
			i.other_immuno		

			

* Open a log file
capture log close
log using "$logdir/17_exploratory_analyses", text replace

use "$tempdir/cr_create_analysis_dataset_STSET_covid_icu_ageband_0.dta", clear
keep if ethnicity!=.u

stcox i.kids_cat3 age1 age2 age3 i.male, strata(stp) vce(cluster household_id)

stcox i.kids_cat3 age1 age2 age3 i.male i.obese4cat i.smoke_nomiss ///
i.imd i.tot_adults_hh, strata(stp) vce(cluster household_id)

stcox i.kids_cat3 age1 age2 age3 i.male i.obese4cat i.smoke_nomiss ///
i.imd i.tot_adults_hh $comordidadjlist, strata(stp) vce(cluster household_id)

stcox i.kids_cat3 age1 age2 age3 i.male i.obese4cat i.smoke_nomiss ///
i.imd i.tot_adults_hh $comordidadjlist i.ethnicity, strata(stp) vce(cluster household_id)


log close
