from cohortextractor import codelist_from_csv

holder_codelist = codelist_from_csv("codelists/opensafely-structured-medication-review-nhs-england.csv",
                              system="snomed",
                              column="code",)

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
oc_local_codes_snomed = codelist_from_csv(
    "codelists/martinaf-online-consultations-snomed-v01-28bba9bc.csv", 
    system = "snomed", 
    column = "code"
)
