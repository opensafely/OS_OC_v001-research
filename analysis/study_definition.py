
# Import functions

from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    Measure,
    codelist_from_csv
)

# Import codelists
from codelists import *


start_date = "2020-12-07"
end_date = "2021-02-01"


# Specifiy study defeinition

study = StudyDefinition(
    index_date="2020-12-07",
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "exponential_increase",
        "incidence": 0.1,
    },
    
    population=patients.satisfying(
        """
        registered AND
        (NOT died) AND
        (sex = 'F' OR sex='M') AND
        (age != 0)
        """,

        registered=patients.registered_as_of(
            "index_date",
            return_expectations={"incidence": 0.9},
        ),

        died=patients.died_from_any_cause(
            on_or_before="index_date",
            returning="binary_flag",
            return_expectations={"incidence": 0.1}
        ),
    ),

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

    practice=patients.registered_practice_as_of(
        "index_date",
        returning="pseudo_id",
        return_expectations={
            "int": {"distribution": "normal", "mean": 25, "stddev": 5}, "incidence": 0.5}
    ),

    region=patients.registered_practice_as_of(
        "index_date",
        returning="nuts1_region_name",
        return_expectations={"category": {"ratios": {
            "North East": 0.1,
            "North West": 0.1,
            "Yorkshire and the Humber": 0.1,
            "East Midlands": 0.1,
            "West Midlands": 0.1,
            "East of England": 0.1,
            "London": 0.2,
            "South East": 0.2, }}}
    ),

    event_x =patients.with_these_clinical_events(
        codelist=holder_codelist,
        between=["index_date", "index_date + 1 month"],
        returning="binary_flag",
        return_expectations={"incidence": 0.5}
    ),

    event_x_event_code=patients.with_these_clinical_events(
        codelist=holder_codelist,
        between=["index_date", "index_date + 1 month"],
        returning="code",
        return_expectations={"category": {
            "ratios": {"1239511000000100": 1}}, }
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


    
]
