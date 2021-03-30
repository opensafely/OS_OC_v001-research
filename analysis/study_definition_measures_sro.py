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
        (age !=0) AND
        (NOT died) AND
        (registered)
        """,
        
        died = patients.died_from_any_cause(
		    on_or_before="index_date",
		    returning="binary_flag"
	    ),
        registered = patients.registered_as_of("index_date"),
        age=patients.age_as_of("index_date"),
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

    OC_OC10=patients.with_these_clinical_events(
        oc_local_codes,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_Y1f3b=patients.with_these_clinical_events(
        oc_Y1f3b,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),


    OC_XUkjp=patients.with_these_clinical_events(
        oc_XUkjp,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_XaXcK=patients.with_these_clinical_events(
        oc_XaXcK,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_XVCTw=patients.with_these_clinical_events(
        oc_XVCTw,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_XUuWQ=patients.with_these_clinical_events(
        oc_XUuWQ,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_XV1pT=patients.with_these_clinical_events(
        oc_XV1pT,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_computerlink=patients.with_these_clinical_events(
        oc_computerlink,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_alertreceived=patients.with_these_clinical_events(
        oc_alertreceived,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),

    OC_Y22b4=patients.with_these_clinical_events(
        oc_Y22b4,        
        between = ["index_date", "index_date + 1 month"],    
        returning="number_of_matches_in_period",        
        return_expectations={
            "incidence": 0.5,
            "int": {"distribution": "normal", "mean": 3, "stddev": 0.5}},
    ),


    
)

measures = [
    Measure(
        id="gpc_practice",
        numerator="gp_consult_count",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_Y1f3b_practice",
        numerator="OC_Y1f3b",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_XUkjp_practice",
        numerator="OC_XUkjp",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_XaXcK_practice",
        numerator="OC_XaXcK",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_XVCTw_practice",
        numerator="OC_XVCTw",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_XUuWQ_practice",
        numerator="OC_XUuWQ",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_XV1pT_practice",
        numerator="OC_XV1pT",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_computerlink_practice",
        numerator="OC_computerlink",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_alertreceived_practice",
        numerator="OC_alertreceived",
        denominator="population",
        group_by="practice"
    ),
    Measure(
        id="OC_Y22b4_practice",
        numerator="OC_Y22b4",
        denominator="population",
        group_by="practice"
    ),

]