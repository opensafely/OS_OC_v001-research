# Adapted from William Hume's Tutorial 3: https://nbviewer.jupyter.org/github/opensafely/os-demo-research/blob/master/rmarkdown/Rdemo.html
# Adapted for EMIS 

# Import functions

from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
    combine_codelists,
    Measure
)

# Import codelists
from codelists_emis import *

# To loop over codes. Taken from longcovid repo
def make_variable(code):
    return {
        f"snomed_{code}": (
            patients.with_these_clinical_events(
                codelist([code], system="snomed"),
                returning="number_of_matches_in_period",
                include_date_of_match=False,
                #date_format="YYYY-MM-DD",
                between=[start_date, end_date],
                return_expectations={
                    "incidence": 0.1,
                    "int": {"distribution": "normal", "mean": 3, "stddev": 1},
                },
            )
        )
    }

def loop_over_codes(code_list):
    variables = {}
    for code in code_list:
        variables.update(make_variable(code))
    return variables


# Specify study definition
start_date = "2019-01-01"
end_date = "2020-12-31"

study = StudyDefinition(
    # Configure the expectations framework
    
    index_date = start_date,
    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "exponential_increase",
        "incidence":1
    },


    # Study population
    population = patients.satisfying(
        """
        (age_ !=0) AND
        (NOT died) AND
        (registered)
        """,
        
        died = patients.died_from_any_cause(
		    on_or_before="index_date",
		    returning="binary_flag"
	    ),
        registered = patients.registered_as_of("index_date"),
        age_=patients.age_as_of("index_date"),
    ),

    #### Location / Registration ## EMIS: removed regionSTP due to mapping coverage concerns
    #
    #
    # Practice
    practice = patients.registered_practice_as_of(
         "index_date",
         returning = "pseudo_id",
         return_expectations={
             "int": {"distribution": "normal", "mean": 100, "stddev": 20}
         },
    ),


    #### CONSULTATION INFORMATION . # GP consult removed as no equivalent querying functionality as of yet
    #
    #
    snomed_OCall=patients.with_these_clinical_events(
        oc_local_codes_snomed,        
        between = [start_date, end_date],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    **loop_over_codes(oc_local_codes_snomed),
    
)