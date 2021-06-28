from cohortextractor import (
    codelist_from_csv,
    codelist
)

##### Local codelists, query data set (MDS) - snomed (following codelistbuilder https://codelists.opensafely.org/codelist/user/martinaf/online-consultations-snomed-v01/28bba9bc/)
oc_local_codes_snomed = codelist_from_csv(
    "codelists-local/martinaf-online-consultations-snomed-v01-28bba9bc.csv", 
    system = "snomed", 
    column = "code"
)

oc_local_codes_snomed_min = codelist_from_csv(
    "codelists-local/martinaf-online-consultations-snomed-v01-28bba9bc_min.csv", 
    system = "snomed", 
    column = "code"
)












