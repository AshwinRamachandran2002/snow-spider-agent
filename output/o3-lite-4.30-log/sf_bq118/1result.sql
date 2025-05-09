WITH discharge_counts AS (
    SELECT
        DR."AgeRecode27" AS age_code,
        DR."Icd10Code",
        COUNT(*)         AS death_count
    FROM "DEATH"."DEATH"."DEATHRECORDS" DR
    JOIN "DEATH"."DEATH"."ICD10CODE" IC
      ON DR."Icd10Code" = IC."Code"
    WHERE DR."RaceRecode3" = 1
      AND IC."Description" ILIKE '%discharge%'
      AND IC."Description" NOT ILIKE '%urethral discharge%'
      AND IC."Description" NOT ILIKE '%discharge of firework%'
      AND IC."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
    GROUP BY DR."AgeRecode27", DR."Icd10Code"
),
discharge_avg AS (
    SELECT
        age_code,
        AVG(death_count) AS avg_discharge
    FROM discharge_counts
    GROUP BY age_code
),
vehicle_counts AS (
    SELECT
        DR."AgeRecode27" AS age_code,
        DR."Icd10Code",
        COUNT(*)         AS death_count
    FROM "DEATH"."DEATH"."DEATHRECORDS" DR
    JOIN "DEATH"."DEATH"."ICD10CODE" IC
      ON DR."Icd10Code" = IC."Code"
    WHERE DR."RaceRecode3" = 1
      AND IC."Description" ILIKE '%vehicle%'
    GROUP BY DR."AgeRecode27", DR."Icd10Code"
),
vehicle_avg AS (
    SELECT
        age_code,
        AVG(death_count) AS avg_vehicle
    FROM vehicle_counts
    GROUP BY age_code
)
SELECT
    AR."Description"                                               AS age_group,
    ROUND(d.avg_discharge - v.avg_vehicle, 4)                      AS higher_avg_deaths
FROM discharge_avg d
JOIN vehicle_avg v  ON d.age_code = v.age_code
JOIN "DEATH"."DEATH"."AGERECODE27" AR ON AR."Code" = d.age_code
ORDER BY d.age_code;