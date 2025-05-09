/*  Vehicle- and Firearm-related deaths (ages 12-18) –
    total deaths and deaths among people whose race description contains “black”                */

WITH
/* --------------------------------------------------------------------------- */
/* 1.  Deaths that involved an ICD-10 code whose description contains “vehicle” */
vehicle_deaths AS (
    SELECT DISTINCT
           dr."Id"               AS "DeathId",
           dr."Age",
           CASE
                WHEN r."Description" ILIKE '%black%' THEN 1
                ELSE 0
           END                   AS "IsBlack"
    FROM DEATH.DEATH.DEATHRECORDS         dr
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS eac
              ON dr."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE            icd
              ON eac."Icd10Code" = icd."Code"
    LEFT JOIN DEATH.DEATH.RACE            r
              ON dr."Race" = r."Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND icd."Description" ILIKE '%vehicle%'
),
vehicle_counts AS (
    SELECT
        "Age",
        COUNT(*)                    AS "vehicle_total",
        SUM("IsBlack")              AS "vehicle_black"
    FROM vehicle_deaths
    GROUP BY "Age"
),

/* --------------------------------------------------------------------------- */
/* 2.  Deaths that involved an ICD-10 code whose description contains “firearm” */
firearm_deaths AS (
    SELECT DISTINCT
           dr."Id"               AS "DeathId",
           dr."Age",
           CASE
                WHEN r."Description" ILIKE '%black%' THEN 1
                ELSE 0
           END                   AS "IsBlack"
    FROM DEATH.DEATH.DEATHRECORDS         dr
    JOIN DEATH.DEATH.ENTITYAXISCONDITIONS eac
              ON dr."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH.ICD10CODE            icd
              ON eac."Icd10Code" = icd."Code"
    LEFT JOIN DEATH.DEATH.RACE            r
              ON dr."Race" = r."Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND icd."Description" ILIKE '%firearm%'
),
firearm_counts AS (
    SELECT
        "Age",
        COUNT(*)                    AS "firearm_total",
        SUM("IsBlack")              AS "firearm_black"
    FROM firearm_deaths
    GROUP BY "Age"
),

/* --------------------------------------------------------------------------- */
/* 3.  Helper table listing every age 12-18 so that ages with zero deaths show */
ages AS (
    SELECT SEQ4() + 12 AS "Age"
    FROM TABLE(GENERATOR(ROWCOUNT => 7))   -- produces ages 12-18
)

/* --------------------------------------------------------------------------- */
SELECT
       a."Age",
       COALESCE(vc."vehicle_total",  0) AS "VehicleTotalDeaths",
       COALESCE(vc."vehicle_black",  0) AS "VehicleBlackDeaths",
       COALESCE(fc."firearm_total",  0) AS "FirearmTotalDeaths",
       COALESCE(fc."firearm_black",  0) AS "FirearmBlackDeaths"
FROM  ages               a
LEFT  JOIN vehicle_counts vc ON a."Age" = vc."Age"
LEFT  JOIN firearm_counts fc ON a."Age" = fc."Age"
ORDER BY a."Age";