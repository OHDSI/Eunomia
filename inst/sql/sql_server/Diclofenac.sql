INSERT INTO @cohort_database_schema.@cohort_table (
	cohort_definition_id, 
	subject_id, 
	cohort_start_date, 
	cohort_end_date
	)
SELECT CAST(@cohort_definition_id AS INT) AS cohort_definition_id,
	person_id,
	drug_era_start_date,
	drug_era_end_date
FROM @cdm_database_schema.drug_era
WHERE drug_concept_id = 1124300; --diclofenac
