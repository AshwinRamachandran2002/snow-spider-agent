/*  deaths (ages 12-18) that involve
    – any ICD-10 code whose description contains “vehicle”
    – any ICD-10 code whose description contains “firearm”
   For every age, we return:
        • total deaths that mention the keyword (vehicle / firearm)
        • deaths among people whose race description contains “black”            */

WITH  BLACK_CODES AS (                         -- race-recode5 values whose description includes “black”
        SELECT "Code"
        FROM   DEATH.DEATH.RACERECODE5
        WHERE  LOWER("Description") LIKE '%black%'
),
CONDITIONS_BY_CATEGORY AS (                    -- each death record id tagged with “vehicle” or “firearm”
        SELECT DISTINCT e."DeathRecordId", 'vehicle' AS "category"
        FROM   DEATH.DEATH.ENTITYAXISCONDITIONS e
        JOIN   DEATH.DEATH.ICD10CODE           ic  ON e."Icd10Code" = ic."Code"
        WHERE  LOWER(ic."Description") LIKE '%vehicle%'

        UNION ALL

        SELECT DISTINCT e."DeathRecordId", 'firearm' AS "category"
        FROM   DEATH.DEATH.ENTITYAXISCONDITIONS e
        JOIN   DEATH.DEATH.ICD10CODE           ic  ON e."Icd10Code" = ic."Code"
        WHERE  LOWER(ic."Description") LIKE '%firearm%'
)

SELECT
       dr."Age"                                                  AS "Age",
       SUM(CASE WHEN cb."category" = 'vehicle'  THEN 1 ELSE 0 END)                                             AS "Vehicle_Total_Deaths",
       SUM(CASE WHEN cb."category" = 'vehicle'
                AND dr."RaceRecode5" IN (SELECT "Code" FROM BLACK_CODES) THEN 1 ELSE 0 END)                    AS "Vehicle_Black_Deaths",
       SUM(CASE WHEN cb."category" = 'firearm'  THEN 1 ELSE 0 END)                                             AS "Firearm_Total_Deaths",
       SUM(CASE WHEN cb."category" = 'firearm'
                AND dr."RaceRecode5" IN (SELECT "Code" FROM BLACK_CODES) THEN 1 ELSE 0 END)                    AS "Firearm_Black_Deaths"
FROM   DEATH.DEATH.DEATHRECORDS          dr
JOIN   CONDITIONS_BY_CATEGORY            cb   ON dr."Id" = cb."DeathRecordId"
WHERE  dr."Age" BETWEEN 12 AND 18                       -- ages 12 through 18 (inclusive)
  AND (dr."AgeType" = 1 OR dr."AgeType" IS NULL)        -- keep only “years” (1) or unspecified
GROUP  BY dr."Age"
ORDER  BY dr."Age" NULLS LAST;