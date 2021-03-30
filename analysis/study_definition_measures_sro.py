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
start_date = "2019-01-01"
end_date = "2020-12-31"

study = StudyDefinition(
    
    index_date = "2020-12-07",
    # Configure the expectations framework
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


    #### Sociodemographics : age ; sex ; imd ; ethnicity

    age=patients.age_as_of(
        "index_date",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),

    age_band=patients.categorised_as(
        {
            "0": "DEFAULT",
            "0-19": """ age >= 0 AND age < 20""",
            "20-29": """ age >=  20 AND age < 30""",
            "30-39": """ age >=  30 AND age < 40""",
            "40-49": """ age >=  40 AND age < 50""",
            "50-59": """ age >=  50 AND age < 60""",
            "60-69": """ age >=  60 AND age < 70""",
            "70-79": """ age >=  70 AND age < 80""",
            "80+": """ age >=  80 AND age < 120""",
        },
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.001,
                    "0-19": 0.124,
                    "20-29": 0.125,
                    "30-39": 0.125,
                    "40-49": 0.125,
                    "50-59": 0.125,
                    "60-69": 0.125,
                    "70-79": 0.125,
                    "80+": 0.125,
                }
            },
        },

    ),

    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.5, "U": 0.01}},
        }
    ),

    # Ethnicity (6 categories)
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2":0.2, "3":0.2, "4":0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),


    # IMD
    # https://github.com/opensafely/risk-factors-research/issues/45
    # https://github.com/opensafely/covid-vaccine-effectiveness-research/blob/5c2aedebe1fe4b238765d1e12d9086cb34f8924c/analysis/study_definition.py
    imd=patients.categorised_as(
        {
            "0": "DEFAULT",
            "1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation < 32844""",
        },
        index_of_multiple_deprivation=patients.address_as_of(
            start_date,
            returning="index_of_multiple_deprivation",
            round_to_nearest=100,
        ),
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "0": 0.05,
                    "1": 0.19,
                    "2": 0.19,
                    "3": 0.19,
                    "4": 0.19,
                    "5": 0.19,
                }
            },
        },
    ),



    #### Location / Registration
    #
    #
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
    
    # STP
    # https://github.com/opensafely/risk-factors-research/issues/44
    stp=patients.registered_practice_as_of(
        "index_date",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    

    # Practice
    practice = patients.registered_practice_as_of(
         "index_date",
         returning = "pseudo_id",
         return_expectations={
             "int": {"distribution": "normal", "mean": 100, "stddev": 20}
         },
    ),


    #### CONSULTATION INFORMATION
    #
    #
    gp_consult_count=patients.with_gp_consultations(    
        between = ["index_date", "index_date + 1 month"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 4, "stddev": 2},
            "incidence": 0.7,
        },
    ),

    # count of occurrences / matches
    OC_SNOMED=patients.with_these_clinical_events(
        oc_local_codes_snomed,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    # boolean for occurrence in period
    event_x =patients.with_these_clinical_events(
        codelist=oc_local_codes_snomed,
        between=["index_date", "index_date + 1 month"],
        returning="binary_flag",
        return_expectations={"incidence": 0.5}
    ),

    # returns /first/ type of code matched in period?
    event_x_event_code=patients.with_these_clinical_events(
        codelist=oc_local_codes_snomed,
        between=["index_date", "index_date + 1 month"],
        returning="code",
        return_expectations={"category": {
            "ratios": {
                    "1090371000000106":0.1,
                    "1068881000000101": 0.1,
                    "978871000000104": 0.1,
                    "854891000000104": 0.1,
                    "384131000000101": 0.1,
                    "325991000000105": 0.1,
                    "325981000000108": 0.1,
                    "325951000000102": 0.1,
                    "325911000000101": 0.1,
                    "325901000000103":0.1,
                },
            }, }
    ),

    
)

measures = [
    Measure(
        id="1_total",
        numerator="event_x",
        denominator="population",
        group_by=None
    ),

    Measure(
        id="1_event_code",
        numerator="event_x",
        denominator="population",
        group_by=["event_x_event_code"]
    ),

    Measure(
        id="1_practice_only",
        numerator="event_x",
        denominator="population",
        group_by=["practice"]
    ),

    Measure(
        id="1_by_region",
        numerator="event_x",
        denominator="population",
        group_by=["region"],
    ),

    Measure(
        id="1_by_sex",
        numerator="event_x",
        denominator="population",
        group_by=["sex"],
    ),

    Measure(
        id="1_by_age_band",
        numerator="event_x",
        denominator="population",
        group_by=["age_band"],
    ),

    Measure(
        id="1_by_imd",
        numerator="event_x",
        denominator="population",
        group_by=["imd"],
    ),

    Measure(
        id="1_by_ethnicity",
        numerator="event_x",
        denominator="population",
        group_by=["ethnicity"],
    ),

]