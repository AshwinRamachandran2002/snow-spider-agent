/*  Difference in average number of deaths (White decedents only)
    between ICD‑10 codes whose descriptions contain “discharge”
    (excluding the three phrases listed) and those that contain “vehicle”,
    aggregated by AgeRecode27 groups                                           */
WITH
/* --------------------------------------------------------------------------
   1.  Build the two ICD‑10 code lists
--------------------------------------------------------------------------- */
DISCHARGE_CODES AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  "Description" ILIKE '%discharge%'
      AND  "Description" NOT IN (
              'Urethral discharge',
              'Discharge of firework',
              'Legal intervention involving firearm discharge'
          )
),
VEHICLE_CODES AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  "Description" ILIKE '%vehicle%'
),

/* --------------------------------------------------------------------------
   2.  Count deaths (White only) by AgeRecode27 & ICD‑10 code
--------------------------------------------------------------------------- */
DISCHARGE_COUNTS AS (
    SELECT  dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*) AS deaths
    FROM    DEATH.DEATH.DEATHRECORDS dr
    JOIN    DISCHARGE_CODES dc
          ON dr."Icd10Code" = dc."Code"
    WHERE   dr."RaceRecode3" = 1      -- White
    GROUP BY dr."AgeRecode27",
             dr."Icd10Code"
),
VEHICLE_COUNTS AS (
    SELECT  dr."AgeRecode27",
            dr."Icd10Code",
            COUNT(*) AS deaths
    FROM    DEATH.DEATH.DEATHRECORDS dr
    JOIN    VEHICLE_CODES vc
          ON dr."Icd10Code" = vc."Code"
    WHERE   dr."RaceRecode3" = 1      -- White
    GROUP BY dr."AgeRecode27",
             dr."Icd10Code"
),

/* --------------------------------------------------------------------------
   3.  Compute the average (mean) deaths per ICD‑10 code within each age group
--------------------------------------------------------------------------- */
DISCHARGE_AVG AS (
    SELECT  "AgeRecode27",
            AVG(deaths) AS avg_deaths_discharge
    FROM    DISCHARGE_COUNTS
    GROUP BY "AgeRecode27"
),
VEHICLE_AVG AS (
    SELECT  "AgeRecode27",
            AVG(deaths) AS avg_deaths_vehicle
    FROM    VEHICLE_COUNTS
    GROUP BY "AgeRecode27"
)

/* --------------------------------------------------------------------------
   4.  Combine, label age groups, and calculate the difference
--------------------------------------------------------------------------- */
SELECT
    ar27."Description"                                        AS "Age_Group",
    d.avg_deaths_discharge                                    AS "Avg_Deaths_Discharge",
    v.avg_deaths_vehicle                                      AS "Avg_Deaths_Vehicle",
    (d.avg_deaths_discharge - v.avg_deaths_vehicle)           AS "Difference_Discharge_minus_Vehicle"
FROM      DISCHARGE_AVG d
FULL JOIN VEHICLE_AVG   v  USING ("AgeRecode27")
LEFT JOIN DEATH.DEATH.AGERECODE27 ar27
       ON ar27."Code" = COALESCE(d."AgeRecode27", v."AgeRecode27")
ORDER BY  COALESCE(d."AgeRecode27", v."AgeRecode27") NULLS LAST;