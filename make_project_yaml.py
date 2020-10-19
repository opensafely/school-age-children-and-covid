#!/usr/bin/env python
import textwrap


def add_action(
    action_name,
    needs,
    script_name=None,
    output=None,
    args=None,
    output_is_non_sensitive=False,
    logfile=None,
):
    if script_name is None:
        script_name = action_name
    extra_args = ""
    if args:
        first_arg = args.split()[0]
        if first_arg != "worms":
            action_name = f"{action_name}_{first_arg}"
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
    if not isinstance(needs, list):
        needs = [needs]
    if len(needs) <= 2:
        needs_str = "[{}]".format(", ".join(needs))
    else:
        needs_str = "\n        - ".join([""] + needs)
    leaf_action_names.add(action_name)
    for other_action in needs:
        leaf_action_names.discard(other_action)
    action = f"""
    {action_name}:
      needs: {needs_str}
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
    """
    worms_generate_cohort:
      run: cohortextractor:latest generate_cohort --study-definition study_definition_worms
      outputs:
        highly_sensitive:
          cohort: output/input_worms.csv
    """,
]
leaf_action_names = set()


add_action(
    "01_cr_analysis_dataset",
    needs="generate_cohort",
    output={
        "check_data": "tempdata/analysis_dataset.dta",
        "data": "tempdata/cr_create_analysis_dataset_STSET_*_ageband_*.dta",
        "ageband_data": "tempdata/analysis_dataset_ageband_*.dta",
    },
)

add_action(
    "WORMS_01_cr_analysis_dataset",
    needs="worms_generate_cohort",
    output={
        "check_data": "tempdata/analysis_dataset_worms.dta",
        "data": "tempdata/cr_create_analysis_dataset_STSET_worms_ageband_*.dta",
        "ageband_data": "tempdata/analysis_dataset_worms_ageband_*.dta",
    },
)

add_action(
    "02_an_data_checks",
    needs="01_cr_analysis_dataset",
    output={"histogram": "output/01_histogram_outcomes.svg"},
    output_is_non_sensitive=True,
)

add_action(
    "WORMS_02_an_data_checks", needs="WORMS_01_cr_analysis_dataset",
)

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
        logfile=f"04b_an_descriptive_table_2_{outcome}.log",
    )

for outcome in outcomes:
    add_action(
        "06_univariate_analysis",
        needs="01_cr_analysis_dataset",
        args=f"{outcome} kids_cat3 gp_number_kids",
        output={
            "data": f"output/an_univariable_cox_models_{outcome}_AGESEX_*_ageband_*.ster"
        },
        output_is_non_sensitive=True,
    )
    # add_action(
    #     "06a_univariate_analysis_SENSE_12mo",
    #     needs="01_cr_analysis_dataset",
    #     args=f"{outcome} kids_cat3",
    #     output={
    #         "data": f"output/an_univariable_cox_models_{outcome}_AGESEX_*_12mo_ageband_*.ster"
    #     },
    #     output_is_non_sensitive=True,
    #     logfile=f"log/06a_univariate_analysis_SENSE_12mo{outcome}.log",
    # )
    add_action(
        "07a_an_multivariable_cox_models_demogADJ",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output={
            "data": f"output/an_multivariate_cox_models_{outcome}_*_DEMOGADJ_ageband_*.ster"
        },
        output_is_non_sensitive=True,
        logfile=f"log/07a_an_multivariable_cox_models_{outcome}.log",
    )
    add_action(
        "07b_an_multivariable_cox_models_FULL",
        needs="01_cr_analysis_dataset",
        args=outcome,
        output={
            "data": f"output/an_multivariate_cox_models_{outcome}_*_MAINFULLYADJMODEL_ageband_*.ster",
            "other_data": f"output/an_sense_{outcome}_*_ageband_*.ster",
        },
        output_is_non_sensitive=True,
        logfile=f"log/07b_an_multivariable_cox_models_{outcome}.log",
    )
    for i in range(3, 6):
        logfile = None
        if i in (4, 5):
            logfile = f"log/07d_an_multivariable_cox_models_{outcome}_Sense{i}_*.log"
        add_action(
            f"07d_an_multivariable_cox_models_FULL_Sense{i}",
            needs="01_cr_analysis_dataset",
            args=outcome,
            output={"data": f"output/an_sense_{outcome}_*_ageband_*.ster"},
            output_is_non_sensitive=True,
            logfile=logfile,
        )
    # add_action(
    #     "16_exploratory_analysis",
    #     needs="01_cr_analysis_dataset",
    #     args=outcome,
    #     output_is_non_sensitive=True,
    # )
    interaction_keys = ["shield", "time", "weeks", "sex"]
    for key in interaction_keys:
        if key == "weeks" and outcome == "covidadmission":
            script_name = "10a_an_interaction_cox_models_weeks_covidad"
            output = f"output/an_interaction_cox_models_{outcome}_week*_ageband_*.ster"
        else:
            script_name = f"10_an_interaction_cox_models_{key}"
            if key == "weeks":
                output = (
                    f"output/an_interaction_cox_models_{outcome}_week0_ageband_*.ster"
                )
            else:
                output = f"output/an_interaction_cox_models_{outcome}_kids_cat3_*_MAINFULLYADJMODEL_*.ster"

        add_action(
            f"10_an_interaction_cox_models_{key}",
            script_name=script_name,
            needs="01_cr_analysis_dataset",
            args=outcome,
            output={"data": output},
            output_is_non_sensitive=True,
        )

add_action(
    "WORMS_06_univariate_analysis",
    needs="WORMS_01_cr_analysis_dataset",
    args="worms kids_cat3 gp_number_kids",
    output={"data": f"output/an_univariable_cox_models_worms_AGESEX_*_ageband_*.ster"},
    output_is_non_sensitive=True,
)

add_action(
    "WORMS_07a_an_multivariable_cox_models_demogADJ",
    needs="WORMS_01_cr_analysis_dataset",
    args="worms",
    output={
        "data": f"output/an_multivariate_cox_models_worms_*_DEMOGADJ_noeth_ageband_*.ster"
    },
    output_is_non_sensitive=True,
)

add_action(
    "WORMS_07b_an_multivariable_cox_models_FULL",
    needs="WORMS_01_cr_analysis_dataset",
    args="worms",
    output={
        "data": f"output/an_multivariate_cox_models_worms_*_MAINFULLYADJMODEL_noeth_ageband_*.ster",
    },
    output_is_non_sensitive=True,
)
for outcome in outcomes:
    add_action(
        "08_an_tablecontent_HRtable",
        needs=[
            "01_cr_analysis_dataset",
            f"06_univariate_analysis_{outcome}",
            f"07a_an_multivariable_cox_models_demogADJ_{outcome}",
            f"07b_an_multivariable_cox_models_FULL_{outcome}",
        ],
        args=outcome,
        output={"data": f"output/an_tablecontents_HRtable_{outcome}.txt"},
        output_is_non_sensitive=True,
    )
add_action(
    "WORMS_08_an_tablecontent_HRtable",
    needs=[
        "WORMS_01_cr_analysis_dataset",
        "WORMS_06_univariate_analysis",
        "WORMS_07a_an_multivariable_cox_models_demogADJ",
        "WORMS_07b_an_multivariable_cox_models_FULL",
    ],
    args="worms",
    output={"data": f"output/an_tablecontents_HRtable_worms.txt"},
    output_is_non_sensitive=True,
)

add_action(
    "15_anHRfigure_all_outcomes",
    needs=[f"07b_an_multivariable_cox_models_FULL_{outcome}" for outcome in outcomes],
    args=outcome,
    output={
        "data": "output/15_an_tablecontents_HRtable_all_outcomes_ANALYSES.txt",
        "figure": "output/15_an_HRforest_all_outcomes_ageband_*.svg",
    },
    output_is_non_sensitive=True,
    logfile="15_anHRfigure_all_outcomes.log",
)

for outcome in outcomes:
    add_action(
        "11_an_interaction_HR_tables_forest",
        needs=[
            f"10_an_interaction_cox_models_{key}_{outcome}" for key in interaction_keys
        ],
        args=outcome,
        output={"data": f"output/11_an_int_tab_contents_HRtable_{outcome}.txt"},
        output_is_non_sensitive=True,
        logfile=f"11_an_interaction_HR_tables_forest_{outcome}.log",
    )

add_action(
    "11a_an_interaction_HR_tables_forest_WEEKS",
    needs=[
        f"10_an_interaction_cox_models_{key}_{outcome}"
        for key in interaction_keys
        for outcome in outcomes
    ],
    args=outcome,
    output={"data": "output/an_int_tab_contents_HRtable_WEEKS.txt",},
    output_is_non_sensitive=True,
    logfile="11a_an_interaction_HR_tables_forest_WEEKS.log",
)

for outcome in outcomes:
    # add_action(
    #     "09_an_agesplinevisualisation",
    #     needs=[
    #         "01_cr_analysis_dataset",
    #         f"07b_an_multivariable_cox_models_FULL_{outcome}",
    #     ],
    #     args=outcome,
    #     output={"figure": f"output/an_agesplinevisualisation_{outcome}_ageband_*.svg"},
    #     output_is_non_sensitive=True,
    #     logfile="09_an_agesplinevisualisation.log",
    # )
    needs = [
        f"07d_an_multivariable_cox_models_FULL_Sense{i}_{outcome}" for i in range(3, 6)
    ]
    needs += [f"07b_an_multivariable_cox_models_FULL_{outcome}"]
    add_action(
        "12_an_tablecontent_HRtable_SENSE",
        needs=needs,
        args=outcome,
        output={
            "data": f"output/12_an_sense_HRtable_{outcome}_SENSE_ANALYSES.txt",
            "figure": f"output/12_an_HRforest_SENSE_{outcome}_ageband_*.svg",
        },
        output_is_non_sensitive=True,
        logfile=f"12_an_tablecontent_HRtable_SENSE_{outcome}.log",
    )

all_actions_str = "\n        - ".join(sorted(leaf_action_names))
actions.append(
    f"""
    run_all:
      needs:
        - {all_actions_str}
      # In order to be valid this action needs to define a run commmand and
      # some output. We don't really care what these are but the below seems to
      # do the trick.
      run: cohortextractor:latest --version
      outputs:
        moderately_sensitive:
          whatever: project.yaml
    """,
)


print(format_project_yaml(actions))
