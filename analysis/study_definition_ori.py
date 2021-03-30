
# Import functions

from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
    combine_codelists
)

# Import codelists
#from codelists import *
MOCK_oc_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv", system="ctv3", column="CTV3ID"
)

# Local OC codelists, query data set (QDS) - ctv3
oc_local_codes = codelist_from_csv(
    "codelists-local/onlineconsultation_qds_ctv3.csv", 
    system = "ctv3", 
    column = "CTV3Code"
)

oc_Y1f3b = codelist_from_csv("codelists-local/onlineconsultation_Y1f3b_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_XUkjp = codelist_from_csv("codelists-local/onlineconsultation_XUkjp_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_XaXcK = codelist_from_csv("codelists-local/onlineconsultation_XaXcK_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_XVCTw = codelist_from_csv("codelists-local/onlineconsultation_XVCTw_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_XUuWQ = codelist_from_csv("codelists-local/onlineconsultation_XUuWQ_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_XV1pT = codelist_from_csv("codelists-local/onlineconsultation_XV1pT_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_computerlink = codelist_from_csv("codelists-local/onlineconsultation_computerlink_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_alertreceived = codelist_from_csv("codelists-local/onlineconsultation_alertreceived_ctv3.csv", system = "ctv3", column = "CTV3Code")
oc_Y22b4 = codelist_from_csv("codelists-local/onlineconsultation_Y22b4_ctv3.csv", system = "ctv3", column = "CTV3Code")

# Local codelists, query data set (MDS) - snomed (following codelistbuilder https://codelists.opensafely.org/codelist/user/martinaf/online-consultations-snomed-v01/28bba9bc/)
from codelists import *

# Specifiy study definition

start_date = "2019-01-01"
end_date = "2020-12-31"

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": start_date, "latest": end_date},
        "rate": "exponential_increase",
        "incidence":1
    },

    
    # This line defines the study population
    population=patients.registered_with_one_practice_between(
        start_date, end_date
    ),

    ### SOCIODEMOGRAPHICS
    #
    # Age
    # https://github.com/opensafely/risk-factors-research/issues/49
    age=patients.age_as_of(
        start_date,
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    
    # Sex
    # https://github.com/opensafely/risk-factors-research/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
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
            "U": "DEFAULT",
            "Q1": """index_of_multiple_deprivation >=1 AND index_of_multiple_deprivation < 32844*1/5""",
            "Q2": """index_of_multiple_deprivation >= 32844*1/5 AND index_of_multiple_deprivation < 32844*2/5""",
            "Q3": """index_of_multiple_deprivation >= 32844*2/5 AND index_of_multiple_deprivation < 32844*3/5""",
            "Q4": """index_of_multiple_deprivation >= 32844*3/5 AND index_of_multiple_deprivation < 32844*4/5""",
            "Q5": """index_of_multiple_deprivation >= 32844*4/5 AND index_of_multiple_deprivation < 32844""",
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
                    "U": 0.05,
                    "Q1": 0.19,
                    "Q2": 0.19,
                    "Q3": 0.19,
                    "Q4": 0.19,
                    "Q5": 0.19,
                }
            },
        },
    ),


    #### HOUSEHOLD INFORMATION
    #
    #
    # Carehome status
    care_home_type=patients.care_home_status_as_of(
        start_date,
        categorised_as={
            "PC": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "PN": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "PS": "IsPotentialCareHome",
            "U": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "U": 0.85,},},
        },
    ),

    # Househould size # Household data only currently available for 2020-02-01
    hh_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 3, "stddev": 1},
            "incidence": 1,
        }
    ),


    #### Location / Registration
    #
    #
    # NUTS1 Region
    region=patients.registered_practice_as_of(
        start_date,
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
        start_date,
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    

    # Practice
    practice = patients.registered_practice_as_of(
         start_date,
         returning = "pseudo_id",
         return_expectations={
             "int": {"distribution": "normal", "mean": 100, "stddev": 20}
         },
    ),


    # Rural vs Urban
    # https://github.com/opensafely/risk-factors-research/issues/47
    rural_urban=patients.address_as_of(
        start_date,
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
 

    #### CONSULTATION INFORMATION
    #
    #
    gp_consult_count=patients.with_gp_consultations(
        between=[start_date, "today"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 4, "stddev": 2},
            "date": {"earliest": start_date, "latest": "today"},
            "incidence": 0.7,
        },
    ),

    latest_consultation_date=patients.date_of(
    "gp_consult_count", date_format="YYYY-MM"
    ),

    has_consultation_history=patients.with_complete_gp_consultation_history_between(
        start_date, end_date, return_expectations={"incidence": 0.9},
    ),


    OC_instance_ctv3=patients.with_these_clinical_events(
        oc_local_codes,    
        between=[start_date, end_date],
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_instance_snomed=patients.with_these_clinical_events(
        oc_local_codes_snomed,    
        between=[start_date, end_date],
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    # Episode count - could use for 'repeat' appointment?
    OC_episode_count=patients.with_these_clinical_events(
        oc_local_codes,
        between=[start_date, end_date],
        returning="number_of_episodes",
        episode_defined_as="series of events each <= 14 days apart",
        return_expectations={
            "int": {"distribution": "normal", "mean": 2, "stddev": 1},
            "incidence": 0.2,

        }
    ),


####CONDITIONS
#
#
#
    has_disability=patients.with_these_clinical_events(
        combine_codelists(learning_disability_codes,intellectual_disability_codes),
        returning="binary_flag",
        return_expectations={
            "incidence": 0.1
        },
    ),


#### WIDER OUTCOMES
#
#
#
# A&E attendance
    a_e_consult_date=patients.attended_emergency_care(
        on_or_after=start_date,
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest" : start_date},
        "rate" : "exponential_increase"},
    ),

)
