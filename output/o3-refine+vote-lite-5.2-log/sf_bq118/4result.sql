WITH
/* ----------------------------------------------------------------------
   1.  ICD‑10 code sets
-------------------------------------------------------------------------*/
discharge_codes AS (           -- descriptions containing “discharge”
    SELECT  "Code" AS "Icd10Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   LOWER("Description") LIKE '%discharge%'
        AND LOWER("Description") NOT IN
            ('urethral discharge',
             'discharge of firework',
             'legal intervention involving firearm discharge')
),
vehicle_codes   AS (           -- descriptions containing “vehicle”
    SELECT  "Code" AS "Icd10Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   LOWER("Description") LIKE '%vehicle%'
),

/* ----------------------------------------------------------------------
   2.  Death counts for WHITE decedents, by age‑group & ICD‑10 code
-------------------------------------------------------------------------*/
deaths_discharge AS (
    SELECT  dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*) AS deaths
    FROM    DEATH.DEATH.DEATHRECORDS dr
            JOIN discharge_codes dc
                  ON dr."Icd10Code" = dc."Icd10Code"
    WHERE   dr."RaceRecode3" = 1         -- White
      AND   dr."AgeRecode27" IS NOT NULL
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),
deaths_vehicle AS (
    SELECT  dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*) AS deaths
    FROM    DEATH.DEATH.DEATHRECORDS dr
            JOIN vehicle_codes vc
                  ON dr."Icd10Code" = vc."Icd10Code"
    WHERE   dr."RaceRecode3" = 1         -- White
      AND   dr."AgeRecode27" IS NOT NULL
    GROUP BY dr."AgeRecode27", dr."Icd10Code"
),

/* ----------------------------------------------------------------------
   3.  Average deaths per ICD‑10 code within each age group
-------------------------------------------------------------------------*/
avg_discharge AS (
    SELECT  "AgeRecode27",
            AVG(deaths) AS avg_discharge_deaths
    FROM    deaths_discharge
    GROUP BY "AgeRecode27"
),
avg_vehicle AS (
    SELECT  "AgeRecode27",
            AVG(deaths) AS avg_vehicle_deaths
    FROM    deaths_vehicle
    GROUP BY "AgeRecode27"
)

/* ----------------------------------------------------------------------
   4.  Combine, compute the difference, and attach age‑group description
-------------------------------------------------------------------------*/
SELECT
        ar27."Description"                AS "Age_Group",
        COALESCE(ad.avg_discharge_deaths, 0)  AS "Avg_Discharge_Deaths",
        COALESCE(av.avg_vehicle_deaths , 0)   AS "Avg_Vehicle_Deaths",
        COALESCE(ad.avg_discharge_deaths, 0)
        - COALESCE(av.avg_vehicle_deaths , 0) AS "Difference_Discharge_Minus_Vehicle"
FROM        DEATH.DEATH.AGERECODE27 ar27
LEFT JOIN   avg_discharge ad ON ad."AgeRecode27" = ar27."Code"
LEFT JOIN   avg_vehicle   av ON av."AgeRecode27" = ar27."Code"
ORDER BY    ar27."Code";