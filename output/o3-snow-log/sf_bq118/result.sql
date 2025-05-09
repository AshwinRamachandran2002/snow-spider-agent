WITH
-- 1.  ICD-10 codes whose description contains “discharge”, excluding the three
discharge_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH."ICD10CODE"
    WHERE LOWER("Description") LIKE '%discharge%'
      AND LOWER("Description") NOT LIKE '%urethral discharge%'
      AND LOWER("Description") NOT LIKE '%discharge of firework%'
      AND LOWER("Description") NOT LIKE '%legal intervention involving firearm discharge%'
),

-- 2.  ICD-10 codes whose description contains “vehicle”
vehicle_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH."ICD10CODE"
    WHERE LOWER("Description") LIKE '%vehicle%'
),

-- 3.  Death counts for every (age group, ICD-10 code) pair – “discharge”
discharge_counts AS (
    SELECT
        dr."AgeRecode27"     AS age_code,
        dr."Icd10Code"       AS icd10,
        COUNT(*)             AS death_cnt
    FROM DEATH.DEATH."DEATHRECORDS"  dr
    JOIN discharge_codes            dc   ON dr."Icd10Code" = dc."Code"
    WHERE dr."RaceRecode3" = 1                         -- white
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

-- 4.  Average number of deaths per ICD-10 code within each age group – “discharge”
discharge_avg AS (
    SELECT
        age_code,
        AVG(death_cnt) AS discharge_avg
    FROM discharge_counts
    GROUP BY age_code
),

-- 5.  Death counts for every (age group, ICD-10 code) pair – “vehicle”
vehicle_counts AS (
    SELECT
        dr."AgeRecode27"     AS age_code,
        dr."Icd10Code"       AS icd10,
        COUNT(*)             AS death_cnt
    FROM DEATH.DEATH."DEATHRECORDS"  dr
    JOIN vehicle_codes              vc   ON dr."Icd10Code" = vc."Code"
    WHERE dr."RaceRecode3" = 1                         -- white
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

-- 6.  Average number of deaths per ICD-10 code within each age group – “vehicle”
vehicle_avg AS (
    SELECT
        age_code,
        AVG(death_cnt) AS vehicle_avg
    FROM vehicle_counts
    GROUP BY age_code
)

-- 7.  Final result: difference between the two averages for each age group
SELECT
    ar27."Description"                                            AS age_group,
    da.discharge_avg,
    va.vehicle_avg,
    (da.discharge_avg - va.vehicle_avg)                           AS difference_discharge_minus_vehicle
FROM DEATH.DEATH."AGERECODE27"                ar27
LEFT JOIN discharge_avg                       da   ON ar27."Code" = da.age_code
LEFT JOIN vehicle_avg                         va   ON ar27."Code" = va.age_code
ORDER BY ar27."Code" NULLS LAST;