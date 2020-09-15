#!/usr/bin/env python
import textwrap


def add_action(script_name, needs, output=None, arg=None, output_is_non_sensitive=False):
    action_name = script_name
    extra_args = ""
    if arg:
        action_name = f"{script_name}_{arg}"
        extra_args = f" {arg}"
    if output:
        if not output_is_non_sensitive:
            output_spec = "\n        highly_sensitive:"
        else:
            output_spec = ""
        output_spec = f'{output_spec}\n          data: "{output}"'
    else:
        output_spec = ""
    action = f"""
    {action_name}:
      needs: [{needs}]
      run: stata-mp:latest analysis/{script_name}.do{extra_args}
      outputs:
        moderately_sensitive:
          log: log/{script_name}.log{output_spec}
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
    output="tempdata/cr_create_analysis_dataset_STSET_*_ageband_*.dta",
)

add_action("02_an_data_checks", needs="01_cr_analysis_dataset")

add_action("03a_an_descriptive_tables", needs="01_cr_analysis_dataset")

add_action(
    "03b_an_descriptive_tables",
    needs="01_cr_analysis_dataset",
    output="output/03b_an_descriptive_table_1_kids_cat3_ageband*.txt",
    output_is_non_sensitive=True,
)

add_action("04a_an_descriptive_tables", needs="01_cr_analysis_dataset")

outcomes = "non_covid_death covid_tpp_prob covid_death covid_icu covidadmission".split()
outcomes_any = ["any"] + outcomes
for outcome in outcomes:
    add_action(
        "04b_an_descriptive_table_2",
        needs="01_cr_analysis_dataset",
        arg=outcome,
        output=f"output/04b_an_descriptive_table_2_{outcome}_ageband*.txt",
        output_is_non_sensitive=True,
    )


print(format_project_yaml(actions))
