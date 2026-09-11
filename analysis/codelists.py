#######################################################################################
# IMPORT
#######################################################################################
from ehrql import codelist_from_csv

#######################################################################################
# Codelists
#######################################################################################

### USED IN BOTH EASTWOOD and DDSC
# T1DM
diabetes_type1_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-dmtype1_cod.csv",column="code")
diabetes_type1_icd10 = codelist_from_csv("codelists/bristol-type-1-diabetes-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/bristol-type-1-diabetes-icd10.csv",column="code") if len(code) == 3]
# T2DM
diabetes_type2_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-dmtype2_cod.csv",column="code")
diabetes_type2_icd10 = codelist_from_csv("codelists/bristol-type-2-diabetes-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/bristol-type-2-diabetes-icd10.csv",column="code") if len(code) == 3]
# Diabetes of other specified aetiology (Other DM)
diabetes_other_snomed = codelist_from_csv("codelists/bristol-diabetes-of-other-specified-aetiology.csv",column="code")
# Diabetes not otherwise specified (NOS DM) 
diabetes_nos_snomed = codelist_from_csv("codelists/bristol-diabetes-not-otherwise-specified.csv",column="code")
diabetes_nos_icd10 = codelist_from_csv("codelists/bristol-diabetes-not-otherwise-specified-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/bristol-diabetes-not-otherwise-specified-icd10.csv",column="code") if len(code) == 3]
# HbA1c
hba1c_snomed = codelist_from_csv("codelists/opensafely-glycated-haemoglobin-hba1c-tests-numerical-value.csv",column="code")
# Antidiabetic drugs
## only insulin
insulin_dmd = codelist_from_csv("codelists/opensafely-insulin-medication.csv",column="id")
## all but NO insulin
antidiabetic_drugs_dmd = codelist_from_csv("codelists/opensafely-antidiabetic-drugs.csv",column="id")

### ONLY USED IN EASTWOOD
ethnicity_codes = codelist_from_csv(
    "codelists/opensafely-ethnicity-snomed-0removed.csv",
    column="snomedcode",
    category_column="Grouping_6",
)
# Non-diagnostic diabetes codes
diabetes_non_diagnostic_ctv3 = codelist_from_csv("codelists/user-hjforbes-nondiagnostic-diabetes-codes.csv",column="code")
# Gestational diabetes
diabetes_gestational_snomed = codelist_from_csv("codelists/nhsd-primary-care-domain-refsets-gestdiab_cod.csv",column="code")
diabetes_gestational_icd10 = codelist_from_csv("codelists/bristol-gestational-diabetes-icd10.csv",column="code") + [code + 'X' for code in codelist_from_csv("codelists/bristol-gestational-diabetes-icd10.csv",column="code") if len(code) == 3]
## all but NO insulin and NO metformin
non_metformin_dmd = codelist_from_csv("codelists/bristol-non-metformin-oral-antidiabetic.csv",column="code")