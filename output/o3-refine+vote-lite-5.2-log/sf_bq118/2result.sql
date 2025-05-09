/*  Difference in average number of deaths (White decedents only) 
    between ICD‑10 codes whose descriptions contain “discharge”
    (excluding the three specified phrases) and those that contain “vehicle”,
    aggregated by AgeRecode27 groups                                         */

WITH discharge_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%discharge%'
      AND LOWER("Description") NOT LIKE 'urethral discharge%'
      AND LOWER("Description") NOT LIKE 'discharge of firework%'
      AND LOWER("Description") NOT LIKE 'legal intervention involving firearm discharge%'
),
vehicle_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
),

/*  Count deaths for every (age group, ICD‑10 code) pair                     */
discharge_counts AS (
    SELECT
        dr."AgeRecode27"  AS age_code,
        dr."Icd10Code"    AS icd_code,
        COUNT(*)          AS death_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN discharge_codes dc
      ON dr."Icd10Code" = dc."Code"
    WHERE dr."RaceRecode3" = 1          -- White
      AND dr."AgeRecode27" IS NOT NULL
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
vehicle_counts AS (
    SELECT
        dr."AgeRecode27"  AS age_code,
        dr."Icd10Code"    AS icd_code,
        COUNT(*)          AS death_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN vehicle_codes vc
      ON dr."Icd10Code" = vc."Code"
    WHERE dr."RaceRecode3" = 1          -- White
      AND dr."AgeRecode27" IS NOT NULL
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

/*  Average deaths per ICD‑10 code inside each age group                     */
discharge_avg AS (
    SELECT
        age_code,
        AVG(death_cnt) AS avg_discharge_deaths
    FROM discharge_counts
    GROUP BY age_code
),
vehicle_avg AS (
    SELECT
        age_code,
        AVG(death_cnt) AS avg_vehicle_deaths
    FROM vehicle_counts
    GROUP BY age_code
)

/*  Final result with age‑group description and difference                   */
SELECT
    ag."Description"                       AS "Age_Group",
    COALESCE(d.avg_discharge_deaths, 0)    AS "Avg_Discharge_Deaths",
    COALESCE(v.avg_vehicle_deaths, 0)      AS "Avg_Vehicle_Deaths",
    COALESCE(d.avg_discharge_deaths, 0)
      - COALESCE(v.avg_vehicle_deaths, 0)  AS "Difference"
FROM DEATH.DEATH.AGERECODE27 ag
LEFT JOIN discharge_avg d ON ag."Code" = d.age_code
LEFT JOIN vehicle_avg   v ON ag."Code" = v.age_code
WHERE d.age_code IS NOT NULL   -- keep only age groups with discharge data
ORDER BY ag."Code";