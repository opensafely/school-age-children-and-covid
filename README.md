# Association between living with children and outcomes from COVID-19: an OpenSAFELY cohort study of 12 million adults in England

This is the code and configuration for our paper, _Association between living with children and outcomes from COVID-19: an OpenSAFELY cohort study of 12 million adults in England._ 

- The preprint of our paper is available on [MedRxiv here](https://doi.org/10.1101/2020.11.01.20222315)
- The paper has been submitted to an academic peer-reviewed journal
- If you are interested in how we defined our variables, take a look at the [study definition](analysis/study_definition.py); this is written in `python`, but non-programmers should be able to understand what is going on there
- Developers and epidemiologists interested in the code should review our [OpenSAFELY documentation](https://docs.opensafely.org/en/latest/)
- If you are interested in how we defined our code lists, look in the codelists folder. A new tool called OpenSafely Codelists was developed to allow codelists to be versioned and all of the codelists hosted online at codelists.opensafely.org for open inspection and re-use by anyone.


# About the OpenSAFELY framework

The OpenSAFELY framework is a new secure analytics platform for
electronic health records research in the NHS.

Instead of requesting access for slices of patient data and
transporting them elsewhere for analysis, the framework supports
developing analytics against dummy data, and then running against the
real data *within the same infrastructure that the data is stored*.


The framework is under fast, active development to support rapid
analytics relating to COVID19; we're currently seeking funding to make
it easier for outside collaborators to work with our system.  

Read more at [OpenSAFELY.org](https://opensafely.org).
