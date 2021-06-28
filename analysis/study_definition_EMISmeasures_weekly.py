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
                between = ["index_date", "index_date + 6 days"], 
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
start_date = "2020-12-07"
end_date = "2020-12-31"

study = StudyDefinition(
    # Configure the expectations framework
    
    index_date = "2020-12-07",
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
        between = ["index_date", "index_date + 6 days"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    **loop_over_codes(oc_local_codes_snomed_min),
    
)

measures = [
    Measure(
        id="snomed_OCall_practice",
        numerator="snomed_OCall",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="snomed_1068881000000101_practice",
        numerator="snomed_1068881000000101",
        denominator="population",
        group_by="practice"
    ),#1
    # Measure(
    #     id="snomed_1090371000000106_practice",
    #     numerator="snomed_1090371000000106",
    #     denominator="population",
    #     group_by="practice"
    # ),#2
    # Measure(
    #     id="snomed_185320006_practice",
    #     numerator="snomed_185320006",
    #     denominator="population",
    #     group_by="practice"
    # ),#3
    # Measure(
    #     id="snomed_325871000000103_practice",
    #     numerator="snomed_325871000000103",
    #     denominator="population",
    #     group_by="practice"
    # ),#4
    # Measure(
    #     id="snomed_325901000000103_practice",
    #     numerator="snomed_325901000000103",
    #     denominator="population",
    #     group_by="practice"
    # ),#5
    # Measure(
    #     id="snomed_325911000000101_practice",
    #     numerator="snomed_325911000000101",
    #     denominator="population",
    #     group_by="practice"
    # ),#6
    # Measure(
    #     id="snomed_325951000000102_practice",
    #     numerator="snomed_325951000000102",
    #     denominator="population",
    #     group_by="practice"
    # ),#7
    # Measure(
    #     id="snomed_325981000000108_practice",
    #     numerator="snomed_325981000000108",
    #     denominator="population",
    #     group_by="practice"
    # ),#8
    # Measure(
    #     id="snomed_325991000000105_practice",
    #     numerator="snomed_325991000000105",
    #     denominator="population",
    #     group_by="practice"
    # ),#9
    # Measure(
    #     id="snomed_384131000000101_practice",
    #     numerator="snomed_384131000000101",
    #     denominator="population",
    #     group_by="practice"
    # ),#10
    # Measure(
    #     id="snomed_401271004_practice",
    #     numerator="snomed_401271004",
    #     denominator="population",
    #     group_by="practice"
    # ),#11
    # Measure(
    #     id="snomed_448337001_practice",
    #     numerator="snomed_448337001",
    #     denominator="population",
    #     group_by="practice"
    # ),#12
    # Measure(
    #     id="snomed_699249000_practice",
    #     numerator="snomed_699249000",
    #     denominator="population",
    #     group_by="practice"
    # ),#13
    # Measure(
    #     id="snomed_719407002_practice",
    #     numerator="snomed_719407002",
    #     denominator="population",
    #     group_by="practice"
    # ),#14
    # Measure(
    #     id="snomed_763184009_practice",
    #     numerator="snomed_763184009",
    #     denominator="population",
    #     group_by="practice"
    # ),#15
    # Measure(
    #     id="snomed_854891000000104_practice",
    #     numerator="snomed_854891000000104",
    #     denominator="population",
    #     group_by="practice"
    # ),#16
    # Measure(
    #     id="snomed_868184008_practice",
    #     numerator="snomed_868184008",
    #     denominator="population",
    #     group_by="practice"
    # ),#17
    # Measure(
    #     id="snomed_978871000000104_practice",
    #     numerator="snomed_978871000000104",
    #     denominator="population",
    #     group_by="practice"
    # ),#18

]