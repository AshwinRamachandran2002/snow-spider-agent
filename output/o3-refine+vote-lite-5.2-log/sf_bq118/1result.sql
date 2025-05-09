WITH discharge_codes AS (     -- every ICD‑10 whose description includes “discharge”, except the three to ignore
    SELECT  "Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   LOWER("Description") LIKE '%discharge%'
      AND   LOWER("Description") NOT IN
             ('urethral discharge',
              'discharge of firework',
              'legal intervention involving firearm discharge')
),
vehicle_codes AS (           -- every ICD‑10 whose description includes “vehicle”
    SELECT  "Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   LOWER("Description") LIKE '%vehicle%'
),

/* number of WHITE deaths for each ICD‑10 in the “discharge” set, by age group */
discharge_counts AS (
    SELECT
        dr."AgeRecode27"        AS age_code,
        dr."Icd10Code"          AS icd10_code,
        COUNT(*)                AS death_cnt
    FROM   DEATH.DEATH.DEATHRECORDS  dr
           JOIN discharge_codes dc  ON dr."Icd10Code" = dc."Code"
    WHERE  dr."RaceRecode3" = 1       -- White
    GROUP  BY dr."AgeRecode27", dr."Icd10Code"
),

/* number of WHITE deaths for each ICD‑10 in the “vehicle” set, by age group */
vehicle_counts AS (
    SELECT
        dr."AgeRecode27"        AS age_code,
        dr."Icd10Code"          AS icd10_code,
        COUNT(*)                AS death_cnt
    FROM   DEATH.DEATH.DEATHRECORDS  dr
           JOIN vehicle_codes  vc  ON dr."Icd10Code" = vc."Code"
    WHERE  dr."RaceRecode3" = 1       -- White
    GROUP  BY dr."AgeRecode27", dr."Icd10Code"
),

/* average deaths per ICD‑10 code (within the “discharge” set) for each age group */
avg_discharge AS (
    SELECT  age_code,
            AVG(death_cnt)  AS avg_discharge_deaths
    FROM    discharge_counts
    GROUP   BY age_code
),

/* average deaths per ICD‑10 code (within the “vehicle” set) for each age group */
avg_vehicle AS (
    SELECT  age_code,
            AVG(death_cnt)  AS avg_vehicle_deaths
    FROM    vehicle_counts
    GROUP   BY age_code
)

/* final comparison */
SELECT
    ag."Description"                                        AS age_group,
    COALESCE(ad.avg_discharge_deaths, 0)                    AS avg_discharge_deaths,
    COALESCE(av.avg_vehicle_deaths,   0)                    AS avg_vehicle_deaths,
    COALESCE(ad.avg_discharge_deaths, 0)
      - COALESCE(av.avg_vehicle_deaths, 0)                  AS difference
FROM   DEATH.DEATH.AGERECODE27 ag
       LEFT JOIN avg_discharge ad ON ag."Code" = ad.age_code
       LEFT JOIN avg_vehicle   av ON ag."Code" = av.age_code
WHERE  ad.avg_discharge_deaths IS NOT NULL                  -- keep age groups with discharge data
ORDER  BY ag."Code";