
  
********************************************************************************
*
*	Do-file:		05_an_descriptive_plots.do
*
*	Project:		Exposure children and COVID risk
*
*	Programmed by:	hforbes, based on file from Elizabeth Williamson
*
*	Data used:		analysis_dataset.dta
*
*	Data created:	None
*
*	Other output:	Kaplan-Meier plots (intended for publication)
*							output/km_age_sex_covid_death_icu.svg 	
*							output/km_age_sex_covid_tpp_prob

********************************************************************************
*
*	Purpose:		This do-file creates Kaplan-Meier plots by age and sex. 
*					Removed plots for older ages as they have been dropped
*  	plot6opts(lcolor(gs0) lpattern(solid))  		///
*	plot7opts(lcolor(gs0) lpattern(solid))  		///
********************************************************************************
*	
*	Stata routines needed:	grc1leg	
*
********************************************************************************


* Set globals that will print in programs and direct output
global outdir  	  "output" 
global logdir     "log"
global tempdir    "tempdata"

forvalues x=0/1 {


use "$tempdir\cr_create_analysis_dataset_STSET_covid_death_icu_ageband_`x'.dta", clear

****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")					///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(female, replace)
	
	
	
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle(" ")										///
	yscale(range(0, 0.008)) 						///
	ylabel(0 (0.002) 0.008, angle(0) format(%4.3f))	///
	xscale(range(30, 100)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 91 "1 May 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "of COVID-19 death", size(medsmall))
graph export "output/km_age_sex_covid_death_icu_ageband_`x'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph


*********************


use "$tempdir\cr_create_analysis_dataset_STSET_covid_tpp_prob_ageband_`x'.dta", clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")										///
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(female, replace)
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle("Days since 1 Feb 2020")					///
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "TPP Covid-19 case", size(medsmall))
graph export "output/km_age_sex_covid_tpp_prob_ageband_`x'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph


use "$tempdir\cr_create_analysis_dataset_STSET_non_covid_death_ageband_`x'.dta", clear


****************************
*  KM plot by age and sex  *
****************************

*** Intended for publication


* KM plot for females by age		
sts graph if male==0, title("Female") 				///
	failure by(agegroup) 							///
	xtitle(" ")										///
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(female, replace)
* KM plot for males by age		
sts graph if male==1, title("Male") 				///
failure by(agegroup) 								///
	xtitle("Days since 1 Feb 2020")					///
	yscale(range(0, 0.005)) 						///
	ylabel(0 (0.001) 0.005, angle(0) format(%4.3f))	///
	xscale(range(30, 84)) 							///
	xlabel(0 "1 Feb 20" 29 "1 Mar 20" 				///
		60 "1 Apr 20" 84 "25 Apr 20")	 			///
	legend(order(1 2 3 4 5 6)						///
	subtitle("Age group", size(small)) 				///
	label(1 "18-<40") label(2 "40-<50") 			///
	label(3 "50-<60") label(4 "60-<70")				///
	label(5 "70-<80") label(6 "80+")				///
	col(3) colfirst size(small))	noorigin		///
	saving(male, replace)	
* KM plot for males and females 
grc1leg female.gph male.gph, 						///
	t1(" ") l1title("Cumulative probability" "Non covid death", size(medsmall))
graph export "output/km_age_sex_non_covid_death_ageband_`x'.svg", as(svg) replace

* Delete unneeded graphs
erase female.gph
erase male.gph

}



