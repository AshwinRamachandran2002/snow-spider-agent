/*  Average deaths by ICD‑10 description category (“discharge” vs. “vehicle”)
    among White decedents (RaceRecode3 = 1), aggregated by age‑group (AgeRecode27).
    The result shows, for every age‑group that has at least one death from either
    category, the two averages and their difference (discharge − vehicle).        */

WITH
/* --------------------------------------------------------------------------- */
/* 1.  ICD‑10 code lists                                                       */
discharge_codes AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%discharge%'
      AND  LOWER("Description") NOT IN
           ('urethral discharge',
            'discharge of firework',
            'legal intervention involving firearm discharge')
),
vehicle_codes AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%vehicle%'
),

/* --------------------------------------------------------------------------- */
/* 2.  Death counts per age‑group & ICD‑10 code                                */
discharge_counts AS (
    SELECT  dr."AgeRecode27"      AS age_code,
            dr."Icd10Code",
            COUNT(*)              AS death_cnt
    FROM    DEATH.DEATH.DEATHRECORDS dr
    WHERE   dr."RaceRecode3" = 1                       -- White
      AND   dr."Icd10Code" IN (SELECT "Code" FROM discharge_codes)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
vehicle_counts AS (
    SELECT  dr."AgeRecode27"      AS age_code,
            dr."Icd10Code",
            COUNT(*)              AS death_cnt
    FROM    DEATH.DEATH.DEATHRECORDS dr
    WHERE   dr."RaceRecode3" = 1                       -- White
      AND   dr."Icd10Code" IN (SELECT "Code" FROM vehicle_codes)
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

/* --------------------------------------------------------------------------- */
/* 3.  Average deaths per age‑group (across ICD‑10 codes in each category)     */
discharge_avg AS (
    SELECT  age_code,
            AVG(death_cnt) AS avg_deaths_discharge
    FROM    discharge_counts
    GROUP BY age_code
),
vehicle_avg AS (
    SELECT  age_code,
            AVG(death_cnt) AS avg_deaths_vehicle
    FROM    vehicle_counts
    GROUP BY age_code
)

/* --------------------------------------------------------------------------- */
/* 4.  Final result: age group, both averages, and their difference            */
SELECT
    ag."Description"                           AS age_group,
    d.avg_deaths_discharge,
    v.avg_deaths_vehicle,
    COALESCE(d.avg_deaths_discharge, 0)
      - COALESCE(v.avg_deaths_vehicle, 0)      AS difference_discharge_minus_vehicle
FROM        DEATH.DEATH.AGERECODE27 ag
LEFT JOIN   discharge_avg d  ON ag."Code" = d.age_code
LEFT JOIN   vehicle_avg  v  ON ag."Code" = v.age_code
WHERE       d.avg_deaths_discharge IS NOT NULL
         OR v.avg_deaths_vehicle  IS NOT NULL
ORDER BY    ag."Code";