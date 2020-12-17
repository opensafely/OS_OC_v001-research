
# Import functions

from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
    combine_codelists
)

# Import codelists

transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv", system="ctv3", column="CTV3ID"
)

chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID"
)
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID"
)
salbutamol_codes = codelist_from_csv(
    "codelists/opensafely-asthma-inhaler-salbutamol-medication.csv",
    system="snomed",
    column="id",
)
systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")

ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)

learning_disability_codes = codelist_from_csv(
    "codelists/opensafely-learning-disabilities.csv",
    system="ctv3",
    column="CTV3Code"
)

intellectual_disability_codes = codelist_from_csv(
    "codelists/opensafely-intellectual-disability-including-downs-syndrome.csv",
    system="ctv3",
    column="CTV3ID"
)

# Local codelists
oc_local_codes = codelist_from_csv(
    "codelists-local/onlineconsultation_mds.csv", 
    system = "snomed", 
    column = "id"
)

# Specifiy study definition

index_date = "2020-01-01"
start_date = "2020-04-01"

study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": start_date, "latest": "today"},
        "rate": "exponential_increase",
        "incidence":1
    },

    index_date = index_date,
    # This line defines the study population
    population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
    ),

    ### SOCIODEMOGRAPHICS
    #
    # Age
    # https://github.com/opensafely/risk-factors-research/issues/49
    age=patients.age_as_of(
        "2020-02-01",
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
    
    #Ethnicity (16 categories)
    ethnicity_16=patients.with_these_clinical_events(
        ethnicity_codes_16,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {
                "ratios": {
                    "1": 0.0625,
                    "2": 0.0625,
                    "3": 0.0625,
                    "4": 0.0625,
                    "5": 0.0625,
                    "6": 0.0625,
                    "7": 0.0625,
                    "8": 0.0625,
                    "9": 0.0625,
                    "10": 0.0625,
                    "11": 0.0625,
                    "12": 0.0625,
                    "13": 0.0625,
                    "14": 0.0625,
                    "15": 0.0625,
                    "16": 0.0625,
                }
            },
            "incidence": 0.75,
        },
    ),

   
    # Ethnicity (6 categories)
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2":0.2, "3":0.2, "4":0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),


    # IMD
    # https://github.com/opensafely/risk-factors-research/issues/45
    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),


    #### HOUSEHOLD INFORMATION
    #
    #
    # Carehome status
    care_home_type=patients.care_home_status_as_of(
        "2020-02-01",
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

    # Househould size
    hh_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 8, "stddev": 1},
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


    # MSOA
    # https://github.com/opensafely/risk-factors-research/issues/44
    msoa=patients.registered_practice_as_of(
        start_date,
        returning="msoa_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"MSOA1": 0.5, "MSOA2": 0.5}},
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
        "2019-02-01", "2020-01-31", return_expectations={"incidence": 0.9},
    ),

    # Episode count - could use for 'repeat' appointment?
    oc_episode_count=patients.with_these_clinical_events(
        oc_local_codes,
        between=[start_date, "today"],
        returning="number_of_episodes",
        episode_defined_as="series of events each <= 14 days apart",
        return_expectations={
            "int": {"distribution": "normal", "mean": 2, "stddev": 1},
            "incidence": 0.9,

        }
    ),

    ####CONDITIONS
    #
    #
    #
    OC_instance=patients.with_these_clinical_events(
        oc_local_codes,    
        between=[start_date, "today"],
        returning="number_of_matches_in_period",        
        find_first_match_in_period=True,
        include_date_of_match=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),


    has_disability=patients.with_these_clinical_events(
        combine_codelists(learning_disability_codes,intellectual_disability_codes),
        returning="binary_flag",
        return_expectations={
            "incidence": 0.1
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/51
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),

    # https://github.com/opensafely/risk-factors-research/issues/48
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
        },
    ),
    


    # https://codelists.opensafely.org/codelist/opensafely/asthma-inhaler-salbutamol-medication/2020-04-15/
    recent_salbutamol_count=patients.with_these_medications(
        salbutamol_codes,
        between=["2018-02-01", "2020-02-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "incidence": 0.6,
            "int": {"distribution": "normal", "mean": 8, "stddev": 2},
        },
    ),


#### WIDER OUTCOMES
#
#
#
# A&E attendance
    a_e_consult_date=patients.attended_emergency_care(
        on_or_after="2020-02-01",
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest" : "2020-02-01"},
        "rate" : "exponential_increase"},
    ),

)
