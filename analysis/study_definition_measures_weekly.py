# Adapted from William Hume's Tutorial 3: https://nbviewer.jupyter.org/github/opensafely/os-demo-research/blob/master/rmarkdown/Rdemo.html

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
from codelists import *

# Specifiy study definition
start_date = "2020-04-27"
end_date = "2021-03-28"

study = StudyDefinition(
    # Configure the expectations framework
    
    index_date = "2020-04-27",
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


    #### CONSULTATION INFORMATION
    #
    #
    gp_consult_count=patients.with_gp_consultations(    
        between = ["index_date", "index_date + 6 days"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 4, "stddev": 2},
            "incidence": 0.7,
        },
    ),

    snomed_eConsult=patients.with_these_clinical_events(
        ocsnomed_1068881000000101,        
        between = ["index_date", "index_date + 6 days"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    snomed_multimedia=patients.with_these_clinical_events(
        ocsnomed_978871000000104,        
        between = ["index_date", "index_date + 6 days"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    snomed_OCall=patients.with_these_clinical_events(
        oc_local_codes_snomed,        
        between = ["index_date", "index_date + 6 days"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    # NUTS1 Region
    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),

    
)

measures = [
    Measure(
        id="gpc_rate",
        numerator="gp_consult_count",
        denominator="population",
        group_by="region"
    ),
    Measure(
        id="snomed_eConsult_rate",
        numerator="snomed_eConsult",
        denominator="population",
        group_by="region"
    ),
    Measure(
        id="snomed_multimedia_rate",
        numerator="snomed_multimedia",
        denominator="population",
        group_by="region"
    ),
    Measure(
        id="snomed_OCall_all",
        numerator="snomed_OCall",
        denominator="population",
        group_by="region"
    ),

]