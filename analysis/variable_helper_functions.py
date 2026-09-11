#######################################################################################
# HELPER FUNCTIONS for the dataset_definition
#######################################################################################
from ehrql.tables.tpp import (
    apcs,
    clinical_events, 
    medications
)

from ehrql import when

#######################################################################################
### COUNT all prior events (including index_date)
#######################################################################################
## In PRIMARY CARE
# CTV3/Read
def count_matching_event_clinical_ctv3_before(codelist, index_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_before(index_date))
        .count_for_patient()
    )

## In SECONDARY CARE (Hospital Episodes)
def count_matching_event_apc_before(codelist, baseline_date, only_prim_diagnoses=False, where=True):
    query = apcs.where(where).where(apcs.admission_date.is_on_or_before(baseline_date))
    if only_prim_diagnoses:
        # If set to True, then check only primary diagnosis field
        query = query.where(
            apcs.primary_diagnosis.is_in(codelist)
        )
    else:
        # Else, check all diagnoses (default, i.e. when only_prim_diagnoses argument not defined)
        query = query.where(apcs.all_diagnoses.contains_any_of(codelist))
    return query.count_for_patient()

#######################################################################################
### ANY HISTORY of ... and give first ... (including index_date) 
#######################################################################################
## In PRIMARY CARE
# CTV3/Read
def first_matching_event_clinical_ctv3_before(codelist, index_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.ctv3_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_before(index_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )
# Snomed
def first_matching_event_clinical_snomed_before(codelist, index_date, where=True):
    return(
        clinical_events.where(where)
        .where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.date.is_on_or_before(index_date))
        .sort_by(clinical_events.date)
        .first_for_patient()
    )
# Medication
def first_matching_med_dmd_before(codelist, index_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_before(index_date))
        .sort_by(medications.date)
        .first_for_patient()
    )

def last_matching_med_dmd_before(codelist, index_date, where=True):
    return(
        medications.where(where)
        .where(medications.dmd_code.is_in(codelist))
        .where(medications.date.is_on_or_before(index_date))
        .sort_by(medications.date)
        .last_for_patient()
    )

## In SECONDARY CARE (Hospital Episodes)
def first_matching_event_apc_before(codelist, baseline_date, only_prim_diagnoses=False, where=True):
    query = apcs.where(where).where(apcs.admission_date.is_on_or_before(baseline_date))
    if only_prim_diagnoses:
         # If set to True, then check only primary diagnosis field
        query = query.where(
            apcs.primary_diagnosis.is_in(codelist)
        )
    else:
        # Else, check all diagnoses (default, i.e. when only_prim_diagnoses argument not defined)
        query = query.where(apcs.all_diagnoses.contains_any_of(codelist))
    return query.sort_by(apcs.admission_date).first_for_patient()


## This function is a flag for whether someone has at least 2 high consecutive 
## values of HbA1c (within gap_days of each other), between the window 
## [ start_date, end_date]. 
## dataset: dataset to add the column to
## start_date: date to start searching from
## end_date: date to stop searching
## codelist: codes for HbA1c
## threshold: minimum value for high hba1c (48mmol/mol)
## gap_days: maximum days between two consecutive high values (2 years= 730 days)
## limit: number of high readings to check
## column_name: name of the column to add to the dataset
def get_two_consecutive_high_hba1c(dataset, start_date, end_date, codelist, threshold, gap_days, limit, column_name):
    prev_hba1c_date = start_date
    flag = when(False).then(True).otherwise(False)

    base_events = (
        clinical_events.where(clinical_events.snomedct_code.is_in(codelist))
        .where(clinical_events.numeric_value >= threshold)
        .where(clinical_events.date.is_after(start_date))
        .where(clinical_events.date.is_on_or_before(end_date))
        .sort_by(clinical_events.date)
    )

    for i in range(limit):
        event_date = (
            base_events
            .where(base_events.date.is_after(prev_hba1c_date))
            .where(base_events.date.is_not_null())
            .first_for_patient()
            .date
        )
        if i > 0:
            diff_days = (event_date - prev_hba1c_date).days
            gap_ok = when(
                prev_hba1c_date.is_on_or_before(end_date)
                & event_date.is_not_null()
                & (diff_days <= gap_days)
            ).then (True).otherwise(False)
            flag = flag | gap_ok
        prev_hba1c_date = event_date

    dataset.add_column(column_name, flag)



