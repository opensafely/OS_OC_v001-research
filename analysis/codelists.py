from cohortextractor import (
    codelist_from_csv,
    codelist
)

holder_codelist = codelist_from_csv("codelists-local/martinaf-online-consultations-snomed-v01-28bba9bc.csv",
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
    "codelists-local/martinaf-online-consultations-snomed-v01-28bba9bc.csv", 
    #"codelists-local/opensafely-referral-and-signposting-for-long-covid.csv",
    system = "snomed", 
    column = "code"
)

ocsnomed_1068881000000101=codelist(["1068881000000101"], system="snomed")
ocsnomed_978871000000104=codelist(["978871000000104"], system="snomed")
ocsnomed_448337001=codelist(["448337001"], system="snomed")
ocsnomed_868184008=codelist(["868184008"], system="snomed")
ocsnomed_719407002=codelist(["719407002"], system="snomed")
ocsnomed_763184009=codelist(["763184009"], system="snomed")
ocsnomed_185320006=codelist(["185320006"], system="snomed")
ocsnomed_1090371000000106=codelist(["1090371000000106"], system="snomed")
ocsnomed_325951000000102=codelist(["325951000000102"], system="snomed")
ocsnomed_325871000000103=codelist(["325871000000103"], system="snomed")
ocsnomed_384131000000101=codelist(["384131000000101"], system="snomed")
ocsnomed_325911000000101=codelist(["325911000000101"], system="snomed")
ocsnomed_699249000=codelist(["699249000"], system="snomed")
ocsnomed_401271004=codelist(["401271004"], system="snomed")
ocsnomed_325901000000103=codelist(["325901000000103"], system="snomed")
ocsnomed_325981000000108=codelist(["325981000000108"], system="snomed")
ocsnomed_325991000000105=codelist(["325991000000105"], system="snomed")
ocsnomed_854891000000104=codelist(["854891000000104"], system="snomed")




## Sociodemographics / clinical etc
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
