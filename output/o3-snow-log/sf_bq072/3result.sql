WITH
/* -----------------------------------------------------------------
   List every age we have to report on (12-18, inclusive)
------------------------------------------------------------------*/
AGE_LIST AS (
    SELECT column1::NUMBER AS AGE
    FROM VALUES (12),(13),(14),(15),(16),(17),(18)
),

/* -----------------------------------------------------------------
   ICD-10 codes whose text contains “vehicle”  or “firearm”
------------------------------------------------------------------*/
CODES_VEHICLE AS (
    SELECT DISTINCT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
),
CODES_FIREARM AS (
    SELECT DISTINCT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%firearm%'
),

/* -----------------------------------------------------------------
   Deaths (DeathRecordId) that list at least one of those codes
------------------------------------------------------------------*/
DEATH_VEHICLE AS (
    SELECT DISTINCT "DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS
    WHERE "Icd10Code" IN (SELECT "Code" FROM CODES_VEHICLE)
),
DEATH_FIREARM AS (
    SELECT DISTINCT "DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS
    WHERE "Icd10Code" IN (SELECT "Code" FROM CODES_FIREARM)
),

/* -----------------------------------------------------------------
   Race-Recode5 values that correspond to a description
   containing the word “black”
------------------------------------------------------------------*/
BLACK_RACE AS (
    SELECT DISTINCT "Code" AS RACE_CODE
    FROM DEATH.DEATH.RACERECODE5
    WHERE LOWER("Description") LIKE '%black%'
),

/* -----------------------------------------------------------------
   All deaths of 12- through 18-year-olds (one row per record)
------------------------------------------------------------------*/
RELEVANT_DEATHS AS (
    SELECT
        d."Id"            AS DEATH_ID,
        d."Age"           AS AGE,
        d."RaceRecode5"   AS RACE_RECODE5
    FROM DEATH.DEATH.DEATHRECORDS d
    WHERE d."Age" BETWEEN 12 AND 18
),

/* -----------------------------------------------------------------
   Aggregate counts for vehicle-related deaths
------------------------------------------------------------------*/
VEHICLE_COUNTS AS (
    SELECT
        r.AGE,
        COUNT(*)                                                  AS TOTAL_VEHICLE_DEATHS,
        COUNT(CASE WHEN b.RACE_CODE IS NOT NULL THEN 1 END)       AS BLACK_VEHICLE_DEATHS
    FROM RELEVANT_DEATHS r
    JOIN DEATH_VEHICLE v
          ON r.DEATH_ID = v."DeathRecordId"
    LEFT JOIN BLACK_RACE b
          ON r.RACE_RECODE5 = b.RACE_CODE
    GROUP BY r.AGE
),

/* -----------------------------------------------------------------
   Aggregate counts for firearm-related deaths
------------------------------------------------------------------*/
FIREARM_COUNTS AS (
    SELECT
        r.AGE,
        COUNT(*)                                                  AS TOTAL_FIREARM_DEATHS,
        COUNT(CASE WHEN b.RACE_CODE IS NOT NULL THEN 1 END)       AS BLACK_FIREARM_DEATHS
    FROM RELEVANT_DEATHS r
    JOIN DEATH_FIREARM f
          ON r.DEATH_ID = f."DeathRecordId"
    LEFT JOIN BLACK_RACE b
          ON r.RACE_RECODE5 = b.RACE_CODE
    GROUP BY r.AGE
)

/* -----------------------------------------------------------------
   Final result: one row per age with zero-fill where needed
------------------------------------------------------------------*/
SELECT
    a.AGE,
    COALESCE(v.TOTAL_VEHICLE_DEATHS , 0) AS TOTAL_VEHICLE_DEATHS,
    COALESCE(v.BLACK_VEHICLE_DEATHS , 0) AS BLACK_VEHICLE_DEATHS,
    COALESCE(f.TOTAL_FIREARM_DEATHS , 0) AS TOTAL_FIREARM_DEATHS,
    COALESCE(f.BLACK_FIREARM_DEATHS , 0) AS BLACK_FIREARM_DEATHS
FROM AGE_LIST a
LEFT JOIN VEHICLE_COUNTS v ON a.AGE = v.AGE
LEFT JOIN FIREARM_COUNTS f ON a.AGE = f.AGE
ORDER BY a.AGE;