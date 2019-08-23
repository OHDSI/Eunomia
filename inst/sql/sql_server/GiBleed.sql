INSERT INTO @cohort_database_schema.@cohort_table (
	cohort_definition_id, 
	subject_id, 
	cohort_start_date, 
	cohort_end_date
	)
SELECT CAST(@cohort_definition_id AS INT) AS cohort_definition_id,
	condition_occurrence.person_id,
	condition_start_date,
	condition_end_date
FROM @cdm_database_schema.condition_occurrence
WHERE condition_concept_id IN (
		SELECT descendant_concept_id
		FROM @cdm_database_schema.concept_ancestor
		WHERE ancestor_concept_id = 192671 -- Gastrointestinal haemorrhage
		);
