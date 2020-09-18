#!/usr/bin/env python
import textwrap


def add_action(
    script_name,
    needs,
    output=None,
    args=None,
    output_is_non_sensitive=False,
    logfile=None,
):
    action_name = script_name
    extra_args = ""
    if args:
        first_arg = args.split()[0]
        action_name = f"{script_name}_{first_arg}"
        extra_args = f" {args}"
    if output:
        if not output_is_non_sensitive:
            output_spec = "\n        highly_sensitive:"
        else:
            output_spec = ""
        for k, v in output.items():
            output_spec += f'\n          {k}: "{v}"'
    else:
        output_spec = ""
    if logfile is None:
        logfile = f"log/{action_name}.log"
    action = f"""
    {action_name}:
      needs: [{needs}]
      run: stata-mp:latest analysis/{script_name}.do{extra_args}
      outputs:
        moderately_sensitive:
          log: {logfile}{output_spec}
    """
    actions.append(action)


def format_project_yaml(actions):
    project_yaml = """
    version: '1.0'
    actions:
    """

    project_yaml = textwrap.dedent(project_yaml.rstrip().strip("\n"))
    for action in actions:
        action = textwrap.dedent(action.rstrip().strip("\n"))
        action = textwrap.indent(action, "  ")
        project_yaml += f"\n\n{action}"
    return project_yaml


actions = [
    """
    generate_cohort:
      run: cohortextractor:latest generate_cohort --study-definition study_definition
      outputs:
        highly_sensitive:
          cohort: output/input.csv
    """,
]


add_action(
    "01_cr_analysis_dataset",
    needs="generate_cohort",
    output={
        "data": "tempdata/cr_create_analysis_dataset_STSET_*_ageband_*.dta",
        "ageband_data": "tempdata/analysis_dataset_ageband_*.dta",
    },
)

add_action("02_an_data_checks", needs="01_cr_analysis_dataset")

add_action("03a_an_descriptive_tables", needs="01_cr_analysis_dataset")

add_action(
    "03b_an_descriptive_table_1",
    needs="01_cr_analysis_dataset",
    output={"data": "output/03b_an_descriptive_table_1_kids_cat3_ageband*.txt"},
    output_is_non_sensitive=True,
)

add_action("04a_an_descriptive_tables", needs="01_cr_analysis_dataset")

outcomes = "non_covid_death covid_tpp_prob covid_death covid_icu covidadmission".split()
for outcome in outcomes:
    add_action(
        "04b_an_descriptive_table_2",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output={"data": f"output/04b_an_descriptive_table_2_{outcome}_ageband*.txt"},
        output_is_non_sensitive=True,
        logfile="04b_an_descriptive_table_2.log",
    )

outcomes_any = ["any"] + outcomes
for outcome in outcomes_any:
    add_action(
        "06_univariate_analysis",
        needs="01_cr_analysis_dataset",
        args=f"{outcome} kids_cat3 gp_number_kids",
        output={
            "data": f"output/an_univariable_cox_models_{outcome}_AGESEX_*_ageband_*.ster"
        },
        output_is_non_sensitive=True,
    )
    add_action(
        "06a_univariate_analysis_SENSE_12mo",
        needs="01_cr_analysis_dataset",
        args=f"{outcome} kids_cat3",
        output={
            "data": f"output/an_univariable_cox_models_{outcome}_AGESEX_*_12mo_ageband_*.ster"
        },
        output_is_non_sensitive=True,
        logfile=f"log/06a_univariate_analysis_SENSE_12mo{outcome}.log",
    )
    add_action(
        "07a_an_multivariable_cox_models_demogADJ",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output={
            "data": f"output/an_multivariate_cox_models_{outcome}_*_DEMOGADJ_*_ageband_*.ster"
        },
        output_is_non_sensitive=True,
        logfile=f"log/07a_an_multivariable_cox_models_{outcome}.log",
    )
    add_action(
        "07b_an_multivariable_cox_models_FULL",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output={
            "data": f"output/an_multivariate_cox_models_{outcome}_*_MAINFULLYADJMODEL_*_ageband_*.ster",
            "other_data": f"output/an_sense_{outcome}_*_ageband_*.ster",
        },
        output_is_non_sensitive=True,
        logfile=f"log/07b_an_multivariable_cox_models_{outcome}.log",
    )
    for i in range(1, 6):
        logfile = None
        if i in (4, 5):
            logfile = f"log/07b_an_multivariable_cox_models_{outcome}_Sense{i}_*.log"
        add_action(
            f"07b_an_multivariable_cox_models_FULL_Sense{i}",
            needs="01_cr_analysis_dataset",
            args=outcome,
            output={"data": f"output/an_sense_{outcome}_*_ageband_*.ster"},
            output_is_non_sensitive=True,
            logfile=logfile,
        )
    add_action(
        "16_exploratory_analysis",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output_is_non_sensitive=True,
    )
    for key in ["sex", "shield", "time", "weeks"]:
        add_action(
            f"10_an_interaction_cox_models_{key}",
            needs="01_cr_analysis_dataset",
            args=outcome,
            output={
                "data": f"output/an_interaction_cox_models_{outcome}_*_MAINFULLYADJMODEL_agespline_bmicat_noeth_ageband_*.ster"
            },
            output_is_non_sensitive=True,
        )


print(format_project_yaml(actions))
