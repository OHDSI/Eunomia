{DEFAULT @person_sample_size = 2500}

SELECT DISTINCT person_id
INTO #person_sample
FROM (
	SELECT first_use.person_id,
		drug_era_start_date,
		ROW_NUMBER() OVER (
			PARTITION BY drug_concept_id ORDER BY NEWID()
			) AS rn,
		drug_concept_id
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
	) require_obs
WHERE rn < @person_sample_size;


SELECT DISTINCT drug_concept_id AS concept_id
INTO #ingredient_concept
FROM @cdm_database_schema.drug_era
INNER JOIN #person_sample person_sample
	ON person_sample.person_id = drug_era.person_id
INNER JOIN @cdm_database_schema.concept_ancestor
	ON drug_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (21601782, 21602796, 21604686, 21604389, 21603932, 21601387, 21602028, 21600960, 21601664, 21601744, 21601461, 21600046, 21603248, 21600712, 21603890, 21601853, 21604254, 21604489, 21604752);

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

SELECT concept_id
INTO #drug_class_concept
FROM @cdm_database_schema.concept
WHERE concept_id IN (21601782, 21602796, 21604686, 21604389, 21603932, 21601387, 21602028, 21600960, 21601664, 21601744, 21601461, 21600046, 21603248, 21600712, 21603890, 21601853, 21604254, 21604489, 21604752);

SELECT DISTINCT condition_concept_id AS concept_id
INTO #condition_concept
FROM @cdm_database_schema.condition_occurrence
INNER JOIN #person_sample person_sample
	ON person_sample.person_id = condition_occurrence.person_id
INNER JOIN @cdm_database_schema.concept_ancestor
	ON condition_concept_id = descendant_concept_id
WHERE ancestor_concept_id IN (4006969, 438409, 4212540, 255573, 201606, 4182210, 440383, 201820, 318800, 192671, 439727, 432867, 316866, 4104000, 433736, 80180, 255848, 140168, 4030518, 80809, 435783, 4279309, 81893, 81902, 197494, 4134440, 313217, 381591, 317576, 321588, 316139, 4185932, 321052, 440417, 444247, 4044013, 432571, 40481902, 443392, 4112853, 4180790, 443388, 197508, 200962210)
	OR ancestor_concept_id = 192671;

SELECT TOP 10 concept_id
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

SELECT TOP 10 concept_id
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

SELECT TOP 10 concept_id
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

SELECT TOP 10 concept_id
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


SELECT DISTINCT concept_id
INTO #concept_sample
FROM (
	SELECT concept_id
	FROM  #ingredient_concept

	UNION ALL

	SELECT concept_id
	FROM  #drug_concept

	UNION ALL

	SELECT concept_id
	FROM  #drug_class_concept

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

TRUNCATE TABLE #drug_class_concept;

DROP TABLE  #drug_class_concept;

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
