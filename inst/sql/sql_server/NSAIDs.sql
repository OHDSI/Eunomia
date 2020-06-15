INSERT INTO @cohort_database_schema.@cohort_table (
	cohort_definition_id, 
	subject_id, 
	cohort_start_date, 
	cohort_end_date
	)
SELECT CAST(@cohort_definition_id AS INT) AS cohort_definition_id,
  person_id AS subject_id,
  MIN(drug_exposure_start_date) AS cohort_start_date,
  MIN(drug_exposure_end_date) AS cohort_end_date
FROM @cdm_database_schema.drug_exposure
INNER JOIN @cdm_database_schema.concept_ancestor
  ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (1118084, 1124300) -- NSAIDS
GROUP BY person_id;
