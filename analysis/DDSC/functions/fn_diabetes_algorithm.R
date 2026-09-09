fn_diabetes_algorithm <- function(data, column_mapping) {


  data <- data %>%
    rename(
      birth_date = all_of(column_mapping$birth_date),
      last_observable_date = all_of(column_mapping$last_observable_date),
      t1dm_date = all_of(column_mapping$t1dm_date),
      t1dm_count_num = all_of(column_mapping$t1dm_count_num),
      t2dm_date = all_of(column_mapping$t2dm_date),
      t2dm_count_num = all_of(column_mapping$t2dm_count_num),
      otherdm_date = all_of(column_mapping$otherdm_date),
      # No codelist yet
      nosdm_date = all_of(column_mapping$nosdm_date),
      antidiabetic_drug_date = all_of(column_mapping$antidiabetic_drug_date),
      diabetes_medication_date = all_of(column_mapping$diabetes_medication_date),
      insulin_date = all_of(column_mapping$insulin_date),
      # new variable
      two_consecutive_high_hba1c = all_of(column_mapping$two_consecutive_high_hba1c),
      last_insulin_date = all_of(column_mapping$last_insulin_date),
      first_diabetes_diag_or_high_hba1c_date = all_of(column_mapping$first_diabetes_diag_or_high_hba1c_date)
      )

  data <- data %>%
    mutate(
    ## --- Step 0: Temporary helper variables ---
      tmp_birth_year_num = as.numeric(format(as.Date(birth_date, format = "%Y-%m-%d"), "%Y")),
      tmp_first_diabetes_diag_or_high_hba1c_date = as.integer(format(first_diabetes_diag_or_high_hba1c_date, "%Y")), # includes t2dm_date, t1dm_date, otherdm_date, nosdm_date, and first high HbA1c
      tmp_age_1st_diag = tmp_first_diabetes_diag_or_high_hba1c_date - tmp_birth_year_num,
      tmp_age_1st_diag = replace(tmp_age_1st_diag, which(tmp_age_1st_diag < 0), NA),
      # Not currently on insulin: no insulin prescription within the last 6 months
      tmp_not_currently_on_insulin = case_when(
                                              is.na(last_insulin_date) ~ 1L,
                                              last_insulin_date < (last_observable_date - 182.5) ~ 1L,
                                              TRUE ~ NA_integer_
                                            ),

      tmp_t1dm_t2dm_ratio_greater_than_1 = case_when(
                                                      !is.na(t1dm_count_num) & !is.na(t2dm_count_num) & t2dm_count_num != 0 &                                                                                                                                             
                                                       (t1dm_count_num / t2dm_count_num) > 1 ~ 1L,
                                                        TRUE ~ NA_integer_
                                                      ),
      # Create flag for on insulin within 1 year of diagnosis
      tmp_insulin_within_1year_diag = case_when(
                                                !is.na(insulin_date) & !is.na(first_diabetes_diag_or_high_hba1c_date) &
                                                as.numeric(insulin_date - first_diabetes_diag_or_high_hba1c_date) >=0 & 
                                                as.numeric(insulin_date - first_diabetes_diag_or_high_hba1c_date) <= 365 ~ 1,
                                                TRUE ~ NA_integer_
                                                ),

      # More than 1 year from date of diagnosis to last observable date
      tmp_more_than_1year_date_diagnosis_to_last_observable_date = case_when(
                                                                             !is.na(first_diabetes_diag_or_high_hba1c_date) & !is.na(last_observable_date) & 
                                                                             as.numeric(last_observable_date - first_diabetes_diag_or_high_hba1c_date) > 365 ~ 1,
                                                                             TRUE ~ NA_integer_
                                                                 ),
      # Flag for greater than or equal to 2
      tmp_greater_than_2_step9 = case_when(
                                            (!is.na(diabetes_medication_date) +
                                            !is.na(two_consecutive_high_hba1c) +
                                            !is.na(insulin_date)) >=2 ~ 1, 
                                            TRUE ~ NA_integer_
      )
    )   %>%

    ## --- Step 1: Any diabetes other code?
    mutate(step_1 = case_when(!is.na(otherdm_date) ~ "Yes", # => Diabetes Other
                              TRUE ~ "No")
           ) %>%


    ## --- Step 2: Prescribing data available? Denominator: Step 1 == No 
    mutate(step_2 = case_when(step_1 == "No" & !is.na(diabetes_medication_date) ~ "Yes",
                              step_1 == "No" & is.na(diabetes_medication_date) ~ "No",
                              TRUE ~ NA_character_) # NA will only be fulfilled for people not part of denominator
           ) %>%

    ## --- Step 3: Not currently on insulin AND >1 year from diagnosis? Denominator: Step 2 == Yes
    mutate(step_3 = case_when(step_2 == "Yes" & !is.na(tmp_not_currently_on_insulin) & !is.na(tmp_more_than_1year_date_diagnosis_to_last_observable_date) ~ "Yes",
                              step_2 == "Yes" ~ "No",
                              step_2 == "No" ~ "No", # Everyone else with Yes to step 2 but 
                              TRUE ~ NA_character_) # NA will only be fulfilled for people not part of denominator
           ) %>%

    ## --- Step 3.1:Any diabetes type 2 codes? Denominator: step 3 == Yes
    mutate(step_3_1 = case_when(step_3 == "Yes" & !is.na(t2dm_date) ~ "Yes", # => Diabetes type 2
                                step_3 == "Yes" ~ "No", # Everyone else with Yes to step 3 - but any diabetes type 2 condition not met
                                TRUE ~ NA_character_) # NA will only be fulfilled for people not part of the denominator
          )   %>%                                     


    ## --- Step 4: Diabetes Type 1 codes and no diabetes type 2 codes? Denominator: Step 3 == No and step 2 == No
    mutate(step_4 = case_when(step_3 == "No" & !is.na(t1dm_date) & is.na(t2dm_date) ~ "Yes",
                              step_2 == "No" & !is.na(t1dm_date) & is.na(t2dm_date) ~ "Yes",
                              step_3 == "No" | step_2 == "No" ~ "No",
                              TRUE ~ NA_character_) # NA will only be fulfilled for people not part of denominator
           ) %>%

    ## --- Step 5. Diabetes type 2 codes AND no diabetes type 1 codes? Denominator: Step 4 == No
    mutate(step_5 = case_when(step_4 == "No" & !is.na(t2dm_date) & is.na(t1dm_date) ~ "Yes",
                              step_4 == "No" ~ "No",
                              TRUE ~ NA_character_) # NA will only be fulfilled if not part of denominator
           ) %>%

    ## --- Step 6. Both, type 1 DM diagnostic codes and type 2 DM diagnostic codes present? Denominator: Step 5 == No
    mutate(step_6 = case_when(step_5 == "No" & !is.na(t1dm_date) & !is.na(t2dm_date) ~ "Yes",
                              step_5 == "No" & (is.na(t1dm_date) | is.na(t2dm_date)) ~ "No",
                              TRUE ~ NA_character_) # NA will only be fulfilled if not part of denominator
           ) %>%

    ## --- Step 6.1. Ratio of type 1 code count and type 2 code count greater than 1? Denominator: Step 6 == Yes
    mutate(step_6_1 = case_when(step_6 == "Yes" & !is.na(tmp_t1dm_t2dm_ratio_greater_than_1) ~ "Yes", # => Type 1 diabetes
                               step_6 == "Yes" & is.na(tmp_t1dm_t2dm_ratio_greater_than_1) ~ "No",
                               TRUE ~ NA_character_) # NA will only be fulfilled if not part of denominator
           ) %>%
 
    ## --- Step 7. Diagnosed age < 35 years AND on insulin within 1 year of diagnosis Denominator: Step 6 == No
    mutate(step_7 = case_when(step_6 == "No" # this includes only people with both missing t1dm_date & t2dm_date (otherwise fished out further above)
                              & (tmp_age_1st_diag <35 ) & !is.na(tmp_insulin_within_1year_diag) ~ "Yes", # => Type 1 diabetes
                              step_6 == "No" ~ "No", 
                              TRUE ~ NA_character_) # NA will only be fulfilled if not part of denominator.
          ) %>%
    ## --- Step 8. Any diabetes Not otherwise specified code? Denominator: Step 7 == No and step 3.1 == No
    mutate(step_8 = case_when(step_3_1 == "No" & !is.na(nosdm_date) ~ "Yes", # <= Diabetes NOS
                              step_7 == "No" & !is.na(nosdm_date) ~ "Yes",
                              step_3_1 == "No" ~ "No",
                              step_7 == "No" ~ "No",
                              TRUE ~ NA_character_) # NA will only be fulfilled if not part of denominator.
           ) %>%
    
    ## --- Step 9. Greater than or equal to 2 of (antidiabetic_drugs_dmd_date or insulin_dmd_date or greater than or equal to 2 consecutive high hba1c)
    mutate(step_9 = case_when(step_8 == "No" & !is.na(tmp_greater_than_2_step9) ~ "Yes", # <- Diabetes unlikely 
                              step_8 == "No" ~ "No",
                              TRUE ~ NA_character_)   
    ) %>%


## -- Final Diabetes Classification --
mutate (
  cat_diabetes = case_when(

              # DM other conditions
            (step_1 == "Yes" ) ~ "DM Other",

                # DM unlikely conditions
            (    step_1 == "No" & step_2 == "Yes" & step_3 == "No"  & step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "No" & step_9 == "No") | 
                (step_1 == "No" & step_2 == "Yes" & step_3 == "Yes" & step_3_1 == "No"                                                  & step_8 == "No" & step_9 == "No") |
                (step_1 == "No" & step_2 == "No"  &                   step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "No" & step_9 == "No")  ~ "DM unlikely",

              # DM Not Otherwise Specified conditions
            (    step_1 == "No" & step_2 == "Yes" & step_3 == "No" & step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "Yes") |
                (step_1 == "No" & step_2 == "No"  &                  step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "Yes") |
                (step_1 == "No" & step_2 == "Yes" & step_3 == "No" & step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "No" & step_9 == "Yes") |
                (step_1 == "No" & step_2 == "No"  &                  step_4 == "No" & step_5 == "No" & step_6 == "No" & step_7 == "No" & step_8 == "No" & step_9 == "Yes") |
                (step_1 == "No" & step_2 == "Yes" & step_3 == "Yes" & step_3_1 == "No" &                                                 step_8 == "Yes") |
                (step_1 == "No" & step_2 == "Yes" & step_3 == "Yes" & step_3_1 == "No" &                                                 step_8 == "No" & step_9 == "Yes") ~ "DM NOS",
              

              # T2DM conditions 
            (  step_1 == "No" & step_2 == "Yes" & step_3 == "Yes" & step_3_1 == "Yes") | 
              (step_1 == "No" & step_2 == "Yes" & step_3 == "No"  & step_4 == "No"       & step_5 == "Yes") | 
              (step_1 == "No" & step_2 == "Yes" & step_3 == "No"  & step_4 == "No"       & step_5 == "No"     & step_6 == "Yes" & step_6_1 == "No") |
              (step_1 == "No" & step_2 == "No"  & step_4 == "No"  & step_5 == "No"       & step_6 == "Yes"    & step_6_1 == "No") |
              (step_1 == "No" & step_2 == "No"  & step_4 == "No"  & step_5 == "Yes") ~ "T2DM" ,

              # T1DM conditions
            (  step_1 == "No" & step_2 == "Yes" & step_3 == "No" & step_4 == "Yes") |
              (step_1 == "No" & step_2 == "No"  & step_4 == "Yes") |
              (step_1 == "No" & step_2 == "Yes" & step_3 == "No" & step_4 == "No" & step_5 == "No"  & step_6 == "Yes"      & step_6_1 == "Yes") |
              (step_1 == "No" & step_2 == "No"  & step_4 == "No" & step_5 == "No" & step_6 == "Yes" & step_6_1 == "Yes") |
              (step_1 == "No" & step_2 == "Yes" & step_3 == "No" & step_4 == "No" & step_5 == "No"  & step_6 == "No"       & step_7 == "Yes") |
              (step_1 == "No" & step_2 == "No"  & step_4 == "No" & step_5 == "No" & step_6 == "No"  & step_7 == "Yes") ~ "T1DM", 
              


           # Default case (for any other conditions)
          TRUE ~ NA_character_
      )
    ) %>%
    mutate(across(cat_diabetes, ~replace_na(., "DM_unlikely"))) 
     return(data)

} 