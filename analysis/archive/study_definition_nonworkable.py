# Import functions
from cohortextractor import (
    StudyDefinition, 
    patients, 
    codelist, 
    codelist_from_csv,
    filter_codes_by_category,
    combine_codelists
)
# Import codelists
transplant_codes = codelist_from_csv(
    "codelists/opensafely-solid-organ-transplantation.csv", system="ctv3", column="CTV3ID"
)
chronic_cardiac_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-cardiac-disease.csv", system="ctv3", column="CTV3ID"
)
chronic_liver_disease_codes = codelist_from_csv(
    "codelists/opensafely-chronic-liver-disease.csv", system="ctv3", column="CTV3ID"
)
salbutamol_codes = codelist_from_csv(
    "codelists/opensafely-asthma-inhaler-salbutamol-medication.csv",
    system="snomed",
    column="id",
)
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_6",
)
ethnicity_codes_16 = codelist_from_csv(
    "codelists/opensafely-ethnicity.csv",
    system="ctv3",
    column="Code",
    category_column="Grouping_16",
)
systolic_blood_pressure_codes = codelist(["2469."], system="ctv3")
diastolic_blood_pressure_codes = codelist(["246A."], system="ctv3")

# Specifiy study defeinition
study = StudyDefinition(
    # Configure the expectations framework
    default_expectations={
        "date": {"earliest": "2019-01-01", "latest": "today"},
        "rate": "exponential_increase",
    },
    # This line defines the study population
    population=patients.registered_with_one_practice_between(
        "2019-02-01", "2020-02-01"
    ),
    ## SOCIODEMOGRAPHICS
    #
    ## Age
    # https://github.com/opensafely/risk-factors-research/issues/49
    age=patients.age_as_of(
        "2020-02-01",
        return_expectations={
            "rate": "universal",
            "int": {"distribution": "population_ages"},
        },
    ),
    
    ## Sex
    # https://github.com/opensafely/risk-factors-research/issues/46
    sex=patients.sex(
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"M": 0.49, "F": 0.51}},
        }
    ),
    
    ## Ethnicity
    ethnicity=patients.with_these_clinical_events(
        ethnicity_codes,
        returning="category",
        find_last_match_in_period=True,
        include_date_of_match=True,
        return_expectations={
            "category": {"ratios": {"1": 0.2, "2":0.2, "3":0.2, "4":0.2, "5": 0.2}},
            "incidence": 0.75,
        },
    ),
    ## Deprivation
    # https://github.com/opensafely/risk-factors-research/issues/45
    imd=patients.address_as_of(
        "2020-02-01",
        returning="index_of_multiple_deprivation",
        round_to_nearest=100,
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"100": 0.1, "200": 0.2, "300": 0.7}},
        },
    ),
    ## Rural or urban
    # https://github.com/opensafely/risk-factors-research/issues/47
    rural_urban=patients.address_as_of(
        "2020-02-01",
        returning="rural_urban_classification",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"rural": 0.1, "urban": 0.9}},
        },
    ),
    ## Household size
    hh_size=patients.household_as_of(
        "2020-02-01",
        returning="household_size",
        return_expectations={
            "int": {"distribution": "normal", "mean": 8, "stddev": 1},
            "incidence": 1,
        }
    ),
    ### Carehome status
    care_home_type=patients.care_home_status_as_of(
        "2020-02-01",
        categorised_as={
            "PC": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='Y'
              AND LocationRequiresNursing='N'
            """,
            "PN": """
              IsPotentialCareHome
              AND LocationDoesNotRequireNursing='N'
              AND LocationRequiresNursing='Y'
            """,
            "PS": "IsPotentialCareHome",
            "U": "DEFAULT",
        },
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"PC": 0.05, "PN": 0.05, "PS": 0.05, "U": 0.85,},},
        },
    ),




    ## CONDITIONS
    ##
    # https://codelists.opensafely.org/codelist/opensafely/chronic-cardiac-disease/2020-04-08/
    chronic_cardiac_disease=patients.with_these_clinical_events(
        chronic_cardiac_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={"incidence": 0.2},
    ),
    # hello branch world
    # https://codelists.opensafely.org/codelist/opensafely/chronic-liver-disease/2020-06-02/
    chronic_liver_disease=patients.with_these_clinical_events(
        chronic_liver_disease_codes,
        returning="date",
        find_first_match_in_period=True,
        include_month=True,
        return_expectations={
            "incidence": 0.2,
            "date": {"earliest": "1950-01-01", "latest": "today"},
        },
    ),
    # https://github.com/opensafely/risk-factors-research/issues/51
    bmi=patients.most_recent_bmi(
        on_or_after="2010-02-01",
        minimum_age_at_measurement=16,
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 35, "stddev": 10},
        },
    ),
    # https://github.com/opensafely/risk-factors-research/issues/48
    bp_sys=patients.mean_recorded_value(
        systolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 80, "stddev": 10},
        },
    ),
    
    # https://github.com/opensafely/risk-factors-research/issues/48
    bp_dias=patients.mean_recorded_value(
        diastolic_blood_pressure_codes,
        on_most_recent_day_of_measurement=True,
        on_or_before="2020-02-01",
        include_measurement_date=True,
        include_month=True,
        return_expectations={
            "incidence": 0.6,
            "float": {"distribution": "normal", "mean": 120, "stddev": 10},
        },
    ),

    ## NUTS1 Regions
    region=patients.registered_practice_as_of(
        "2020-02-01",
        returning="nuts1_region_name",
        return_expectations={
            "rate": "universal",
            "category": {
                "ratios": {
                    "North East": 0.1,
                    "North West": 0.1,
                    "Yorkshire and the Humber": 0.1,
                    "East Midlands": 0.1,
                    "West Midlands": 0.1,
                    "East of England": 0.1,
                    "London": 0.2,
                    "South East": 0.2,
                },
            },
        },
    ),
    ## STP
    # https://github.com/opensafely/risk-factors-research/issues/44
    stp=patients.registered_practice_as_of(
        "2020-02-01",
        returning="stp_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"STP1": 0.5, "STP2": 0.5}},
        },
    ),
    
    ## GP Practice code
    practice = patients.registered_practice_as_of(
         index_date,
         returning = "pseudo_id",
         return_expectations={
             "int": {"distribution": "normal", "mean": 100, "stddev": 20}
         },
    ),


    ## MSOA
    # https://github.com/opensafely/risk-factors-research/issues/44
    msoa=patients.registered_practice_as_of(
        "2020-02-01",
        returning="msoa_code",
        return_expectations={
            "rate": "universal",
            "category": {"ratios": {"MSOA1": 0.5, "MSOA2": 0.5}},
        },
    ),

 
    # https://codelists.opensafely.org/codelist/opensafely/asthma-inhaler-salbutamol-medication/2020-04-15/
    recent_salbutamol_count=patients.with_these_medications(
        salbutamol_codes,
        between=["2018-02-01", "2020-02-01"],
        returning="number_of_matches_in_period",
        return_expectations={
            "incidence": 0.6,
            "int": {"distribution": "normal", "mean": 8, "stddev": 2},
        },
    ),
    # https://docs.opensafely.org/en/stable/onboarding_analysts/
    organ_transplant=patients.with_these_clinical_events(
        transplant_codes,
        returning='binary_flag',
        return_expectations={
            "incidence": 0.05
        },
    ),
    ## GP CONSULTATION INFORMATION
    ### GP Consultation Rate
    gp_consult_count=patients.with_gp_consultations(
        between=["2019-02-01", "2020-01-31"],
        returning="number_of_matches_in_period",
        return_expectations={
            "int": {"distribution": "normal", "mean": 4, "stddev": 2},
            "date": {"earliest": "2019-03-01", "latest": "2020-01-31"},
            "incidence": 0.7,
        },
    ),
    
    has_consultation_history=patients.with_complete_gp_consultation_history_between(
        "2019-02-01", "2020-01-31", return_expectations={"incidence": 0.9},
    ),
    latest_consultation_date=patients.date_of(
        "gp_consult_count", date_format="YYYY-MM"
    ),
    episode_count=patients.with_these_clinical_events(
        transplant_codes,
        returning="number_of_episodes",
        on_or_before="2020-01-31",
        episode_defined_as="series of events each <= 14 days apart",
        return_expectations={"incidence":0.9,
        "int": {"distribution": "normal", "mean": 4, "stddev": 2}}
    ),

    ## WIDER OUTCOMES
    #
    ## A&E attendance
    a_e_consult_date=patients.attended_emergency_care(
        on_or_after="2019-01-01",
        returning="date_arrived",
        date_format="YYYY-MM-DD",
        find_first_match_in_period=True,
        return_expectations={"date": {"earliest" : "2019-01-01"},
        "incidence":1,
        "rate":"exponential_increase"},
    ),

)
