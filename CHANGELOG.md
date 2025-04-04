# [v0.0.6](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.6)

* Updated CHANGELOG
* Updated ethnicity variable label "South Asian" to "Asian" as per latest work on this topic in OpenSAFELY (https://pubmed.ncbi.nlm.nih.gov/38987774/). Correct codelist already in use.

# [v0.0.5](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.5)

* Updated CHANGELOG
* Updated main.yml to fix race condition in GHA workflow

# [v0.0.4](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.4)

* Changed output formatting to:
* a) more efficient tidyverse coding
* b) clarified suffix
* c) clarified , na = "" for @table_from_file to work 

# [v0.0.3](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.3)

* Allow .cvs.gz output, not only .rds
* Particularly relevant when using the output for @table_from_file in dataset definition, e.g. https://github.com/opensafely/metformin_covid/blob/45fc5739484578b0bc732684d15d73bc015a6671/analysis/dataset_definition_t2dm.py#L46
* Now, both is allowed, whatever the user specifies as df_output / outputs format, e.g. https://github.com/opensafely/metformin_covid/blob/45fc5739484578b0bc732684d15d73bc015a6671/project.yaml#L30 

# [v0.0.2](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.2)

* Column mapping in fn_diabetes_algorithm.R was missing.
* This allows users to provide their own variable names, then mapped to variables in the function. 
* Similar as in data_process.R

# [v0.0.1](https://github.com/opensafely-actions/diabetes-algo/releases/tag/v0.0.1)

* First release of diabetes-algo
