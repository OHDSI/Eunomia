{DEFAULT @person_sample_size = 2500}
{DEFAULT @concept_sample_size = 100}

SELECT DISTINCT first_use.person_id
INTO #person_sample
FROM (
	SELECT person_id,
		MIN(drug_era_start_date) AS drug_era_start_date,
		ROW_NUMBER() OVER (
			PARTITION BY drug_concept_id ORDER BY NEWID()
			) AS rn,
		drug_concept_id
	FROM @cdm_database_schema.drug_era
	WHERE drug_concept_id IN (1118084, 1124300)
	GROUP BY person_id,
		drug_concept_id
	) first_use
INNER JOIN (
	SELECT person_id,
		MIN(observation_period_start_date) AS observation_period_start_date,
		MIN(observation_period_end_date) AS observation_period_end_date
	FROM @cdm_database_schema.observation_period
	GROUP BY person_id
	) first_op
	ON first_use.person_id = first_op.person_id
		AND drug_era_start_date >= DATEADD(DAY, 365, observation_period_start_date)
		AND drug_era_start_date <= observation_period_end_date
WHERE rn < @person_sample_size;

SELECT TOP @concept_sample_size concept_id
INTO #ingredient_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
		drug_concept_id AS concept_id
	FROM @cdm_database_schema.drug_era
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = drug_era.person_id
	GROUP BY drug_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;

SELECT DISTINCT drug_concept_id AS concept_id
INTO #drug_concept
FROM @cdm_database_schema.drug_exposure
INNER JOIN #person_sample person_sample
	ON person_sample.person_id = drug_exposure.person_id
INNER JOIN @cdm_database_schema.concept_ancestor
	ON drug_concept_id = descendant_concept_id
INNER JOIN #ingredient_concept ingredient_concept
	ON ingredient_concept.concept_id = ancestor_concept_id
WHERE drug_concept_id != 0;

SELECT TOP @concept_sample_size concept_id
INTO #condition_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
		condition_concept_id AS concept_id
	FROM @cdm_database_schema.condition_occurrence
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = condition_occurrence.person_id
	GROUP BY condition_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;

SELECT TOP @concept_sample_size concept_id
INTO #device_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
	  device_concept_id AS concept_id
	FROM @cdm_database_schema.device_exposure
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = device_exposure.person_id
	GROUP BY device_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;

SELECT TOP @concept_sample_size concept_id
INTO #procedure_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
		procedure_concept_id AS concept_id
	FROM @cdm_database_schema.procedure_occurrence
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = procedure_occurrence.person_id
	GROUP BY procedure_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;

SELECT TOP @concept_sample_size concept_id
INTO #measurement_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
		measurement_concept_id AS concept_id
	FROM @cdm_database_schema.measurement
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = measurement.person_id
	GROUP BY measurement_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;

SELECT TOP @concept_sample_size concept_id
INTO #observation_concept
FROM (
	SELECT COUNT(DISTINCT person_sample.person_id) AS person_count,
		observation_concept_id AS concept_id
	FROM @cdm_database_schema.observation
	INNER JOIN #person_sample person_sample
		ON person_sample.person_id = observation.person_id
	GROUP BY observation_concept_id
	) tmp
WHERE concept_id != 0
ORDER BY - person_count;


SELECT concept_id
INTO #concept_sample
FROM (
	SELECT concept_id
	FROM  #ingredient_concept

	UNION ALL

	SELECT concept_id
	FROM  #drug_concept

	UNION ALL

	SELECT concept_id
	FROM  #condition_concept

	UNION ALL

	SELECT concept_id
	FROM  #device_concept

	UNION ALL

	SELECT concept_id
	FROM  #procedure_concept

	UNION ALL

	SELECT concept_id
	FROM  #measurement_concept

	UNION ALL

	SELECT concept_id
	FROM  #observation_concept
) union_all;

TRUNCATE TABLE #ingredient_concept;

DROP TABLE  #ingredient_concept;

TRUNCATE TABLE #drug_concept;

DROP TABLE  #drug_concept;

TRUNCATE TABLE #condition_concept;

DROP TABLE  #condition_concept;

TRUNCATE TABLE #device_concept;

DROP TABLE  #device_concept;

TRUNCATE TABLE #procedure_concept;

DROP TABLE  #procedure_concept;

TRUNCATE TABLE #measurement_concept;

DROP TABLE  #measurement_concept;

TRUNCATE TABLE #observation_concept;

DROP TABLE  #observation_concept;
