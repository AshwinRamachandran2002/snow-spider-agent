/*  Difference in the average number of deaths (White decedents) between
    ICD‑10 codes containing “discharge” (with the three unwanted phrases
    excluded) and those containing “vehicle”, aggregated by AgeRecode27      */

WITH
/* ------------------------------------------------------------------ */
/* 1.  Two ICD‑10 code‑lists                                           */
discharge_codes AS (
    SELECT  "Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   "Description" ILIKE '%discharge%'
      AND   "Description" NOT ILIKE '%urethral discharge%'
      AND   "Description" NOT ILIKE '%discharge of firework%'
      AND   "Description" NOT ILIKE '%legal intervention involving firearm discharge%'
),
vehicle_codes AS (
    SELECT  "Code"
    FROM    DEATH.DEATH.ICD10CODE
    WHERE   "Description" ILIKE '%vehicle%'
),

/* ------------------------------------------------------------------ */
/* 2.  How many codes are in each list?  (needed for the “average”)    */
num_discharge AS ( SELECT COUNT(*)::FLOAT AS n FROM discharge_codes ),
num_vehicle   AS ( SELECT COUNT(*)::FLOAT AS n FROM vehicle_codes   ),

/* ------------------------------------------------------------------ */
/* 3.  Death counts for each age‑group, White race only                */
discharge_deaths AS (
    SELECT  d."AgeRecode27",
            COUNT(*) AS total_deaths
    FROM    DEATH.DEATH.DEATHRECORDS d
    JOIN    discharge_codes dc
           ON dc."Code" = d."Icd10Code"
    WHERE   d."RaceRecode3" = 1            -- White
    GROUP BY d."AgeRecode27"
),
vehicle_deaths AS (
    SELECT  d."AgeRecode27",
            COUNT(*) AS total_deaths
    FROM    DEATH.DEATH.DEATHRECORDS d
    JOIN    vehicle_codes vc
           ON vc."Code" = d."Icd10Code"
    WHERE   d."RaceRecode3" = 1            -- White
    GROUP BY d."AgeRecode27"
)

/* ------------------------------------------------------------------ */
/* 4.  Combine everything and compute the difference                   */
SELECT
        ag."Code"                                 AS "AgeRecode27",
        ag."Description"                          AS "Age_Group",
        dd.total_deaths / nd.n                    AS "Avg_Discharge_Deaths",
        vd.total_deaths / nv.n                    AS "Avg_Vehicle_Deaths",
        (dd.total_deaths / nd.n) - (vd.total_deaths / nv.n)
                                                  AS "Difference_Higher_Discharge"
FROM    DEATH.DEATH.AGERECODE27          ag
LEFT JOIN discharge_deaths              dd  ON dd."AgeRecode27" = ag."Code"
LEFT JOIN vehicle_deaths                vd  ON vd."AgeRecode27" = ag."Code"
CROSS JOIN num_discharge                nd
CROSS JOIN num_vehicle                  nv
WHERE   dd.total_deaths IS NOT NULL
     OR vd.total_deaths IS NOT NULL
ORDER BY ag."Code";