
# numpy for random seed - and set random seed
#import numpy as np 
#np.random.seed(209109) # random seed

#######################################################################################
# IMPORT
#######################################################################################
## Import ehrQL functions
from ehrql import (
    create_dataset,
    minimum_of,
    case,
    when,
    days
)


## Import TPP tables
from ehrql.tables.tpp import (
    clinical_events,
    patients,
    ons_deaths
)
from datetime import date

## Import all codelists from codelists.py
from codelists import *

## Import the variable helper functions 
from variable_helper_functions import *


#######################################################################################
# DEFINE or IMPORT the last observable date for DDSC algorithm
#######################################################################################

# last_observable_date_for_people_alive = "2024-12-10"
last_observable_date_for_people_alive  = date(2024, 12, 10)

#######################################################################################
# INITIALISE the dataset and set the dummy dataset size
#######################################################################################
dataset = create_dataset()
dataset.configure_dummy_data(population_size=5000)
dataset.define_population(patients.exists_for_patient())

#######################################################################################
# DEFINE necessary variables to build algo
#######################################################################################
## See add link

# Last observable date constant for people who are alive and date of death for those who have died
dataset.last_observable_date = case(
    when(ons_deaths.date.is_not_null()).then(ons_deaths.date),
    otherwise = last_observable_date_for_people_alive
)

## Demographics
dataset.birth_date = patients.date_of_birth


## Type 1 Diabetes 
# First date from primary+secondary care
dataset.t1dm_date = minimum_of(
    (first_matching_event_clinical_ctv3_before(diabetes_type1_ctv3, dataset.last_observable_date).date),
    (first_matching_event_apc_before(diabetes_type1_icd10, dataset.last_observable_date).admission_date)
)


# Type 1 diabetes count codes (individually and together, for diabetes algo)
t1dm_primarycare_count = count_matching_event_clinical_ctv3_before(diabetes_type1_ctv3, dataset.last_observable_date)
t1dm_hes_count = count_matching_event_apc_before(diabetes_type1_icd10, dataset.last_observable_date)
dataset.t1dm_count_num = t1dm_primarycare_count + t1dm_hes_count


## Type 2 Diabetes
# First date from primary+secondary care
dataset.t2dm_date = minimum_of(
    (first_matching_event_clinical_ctv3_before(diabetes_type2_ctv3, dataset.last_observable_date).date),
    (first_matching_event_apc_before(diabetes_type2_icd10, dataset.last_observable_date).admission_date)
)

# Count codes (individually and together, for diabetes algo)
t2dm_primarycare_count = count_matching_event_clinical_ctv3_before(diabetes_type2_ctv3, dataset.last_observable_date)
t2dm_hes_count = count_matching_event_apc_before(diabetes_type2_icd10, dataset.last_observable_date)
dataset.t2dm_count_num = t2dm_primarycare_count + t2dm_hes_count



# Diabetes Other for DDSC algorithm
dataset.otherdm_date = first_matching_event_clinical_ctv3_before(diabetes_other_ctv3, dataset.last_observable_date).date

# Diabetes Not otherwise specified (NOS) for DDSC algorithm
# Using diabetes other as a placeholder for NOS until a codelist is created
dataset.nosdm_date = first_matching_event_clinical_ctv3_before(diabetes_other_ctv3, dataset.last_observable_date).date



## Diabetes drugs 
# First dates
dataset.insulin_date = first_matching_med_dmd_before(insulin_dmd, dataset.last_observable_date).date
dataset.antidiabetic_drug_date = first_matching_med_dmd_before(antidiabetic_drugs_dmd, dataset.last_observable_date).date

# Last insulin date
dataset.last_insulin_date = last_matching_med_dmd_before(insulin_dmd, dataset.last_observable_date).date

# Identify first date (in same period) that any diabetes medication was prescribed
dataset.diabetes_medication_date = minimum_of(dataset.insulin_date, dataset.antidiabetic_drug_date)



# Identify date of diagnosis which is; first date (in same period) that any diabetes diagnosis codes were recorded or
# the first high HbA1C if more than a year before first diabetes code

# Identify first date of any diabetes diagnosis codes
dataset.first_diabetes_diag_date = minimum_of(
  dataset.t1dm_date, 
  dataset.t2dm_date,
  dataset.otherdm_date,
  dataset.nosdm_date
)

# Date of first high HbA1c measure if more than a year before first diabetes code
dataset.first_high_hba1c_date = case( 
  when(dataset.first_diabetes_diag_date.is_not_null()).then(
  clinical_events.where(
    clinical_events.snomedct_code.is_in(hba1c_snomed))
    .where(clinical_events.numeric_value >= 48 )
    .where(clinical_events.date.is_on_or_before(dataset.first_diabetes_diag_date - days(365))) 
    .sort_by(clinical_events.date)
    .first_for_patient() 
    .date
),
  when(dataset.first_diabetes_diag_date.is_null()).then(
    clinical_events.where(
    clinical_events.snomedct_code.is_in(hba1c_snomed))
    .where(clinical_events.numeric_value >= 48)
    .sort_by(clinical_events.date)
    .first_for_patient()
    .date
  )
  )

## Get two consecutive high hba1c 
get_two_consecutive_high_hba1c(
    dataset,
    start_date=patients.date_of_birth,
    end_date=dataset.last_observable_date,
    codelist=hba1c_snomed,
    threshold=48,
    gap_days=730,
    limit=30,
    column_name="two_consecutive_high_hba1c"
)



# Date of diagnosis for DDSC 
dataset.first_diabetes_diag_or_high_hba1c_date = minimum_of(
    dataset.first_diabetes_diag_date,
    dataset.first_high_hba1c_date
)
