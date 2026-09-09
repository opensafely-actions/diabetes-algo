#######################################################################################
# IMPORT
#######################################################################################
from ehrql import codelist_from_csv

#######################################################################################
# Codelists
#######################################################################################
## Ethnicity
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="snomedcode",
    category_column="Grouping_6",
)

## DIABETES
# T1DM
diabetes_type1_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-dmtype1_cod.csv",column="code")
diabetes_type1_icd10 = codelist_from_csv("codelists/reducehf-type-1-diabetes-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/reducehf-type-1-diabetes-icd10.csv",column="code") if len(code) == 3]
# T2DM
diabetes_type2_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-dmtype2_cod.csv",column="code")
diabetes_type2_icd10 = codelist_from_csv("codelists/reducehf-type-2-diabetes-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/reducehf-type-2-diabetes-icd10.csv",column="code") if len(code) == 3]
# Other or non-specific diabetes
diabetes_other_ctv3 = codelist_from_csv("codelists/user-hjforbes-other-or-nonspecific-diabetes.csv",column="code")
# Gestational diabetes
diabetes_gestational_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-gestdiab_cod.csv",column="code")
diabetes_gestational_icd10 = codelist_from_csv("codelists/user-alainamstutz-gestational-diabetes-icd10-bristol.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/user-alainamstutz-gestational-diabetes-icd10-bristol.csv",column="code") if len(code) == 3]
# Non-diagnostic diabetes codes
diabetes_non_diagnostic_ctv3 = codelist_from_csv("codelists/user-hjforbes-nondiagnostic-diabetes-codes.csv",column="code")
# HbA1c
hba1c_snomed = codelist_from_csv("codelists/opensafely-glycated-haemoglobin-hba1c-tests-numerical-value.csv",column="code")
# Antidiabetic drugs
### only insulin
insulin_dmd = codelist_from_csv("codelists/opensafely-insulin-medication.csv",column="id")
### all but NO insulin
antidiabetic_drugs_dmd = codelist_from_csv("codelists/opensafely-antidiabetic-drugs.csv",column="id")
### all but NO insulin and NO metformin
non_metformin_dmd = codelist_from_csv("codelists/user-alainamstutz-non-metformin-oral-antidiabetic.csv",column="code")

## additional codelists for the DDSC algorithm