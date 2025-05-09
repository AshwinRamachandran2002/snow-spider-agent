/*--------------------------------------------------------------------
  Deaths of 12–18-year-olds that involve
    1) an ICD-10 code whose description contains ‘vehicle’
    2) an ICD-10 code whose description contains ‘firearm’

  For every age (12-18) return
      • total deaths involving vehicles
      • deaths involving vehicles in which the decedent is Black
      • total deaths involving firearms
      • deaths involving firearms in which the decedent is Black
  EntityAxisConditions is used to associate ICD-10 codes with each
  death record.  “Black” race is identified from RACERECODE5 rows
  whose description contains the word ‘black’.
--------------------------------------------------------------------*/
WITH
/* ICD-10 code sets */
vehicle_codes AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%vehicle%'
),
firearm_codes AS (
    SELECT "Code"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%firearm%'
),

/* Deaths that mention at least one “vehicle” / “firearm” code */
vehicle_deaths AS (
    SELECT DISTINCT "DeathRecordId"
    FROM   DEATH.DEATH.ENTITYAXISCONDITIONS e
           JOIN vehicle_codes v
             ON e."Icd10Code" = v."Code"
),
firearm_deaths AS (
    SELECT DISTINCT "DeathRecordId"
    FROM   DEATH.DEATH.ENTITYAXISCONDITIONS e
           JOIN firearm_codes f
             ON e."Icd10Code" = f."Code"
),

/* Codes that correspond to “Black” */
black_codes AS (
    SELECT "Code"
    FROM   DEATH.DEATH.RACERECODE5
    WHERE  LOWER("Description") LIKE '%black%'
),

/* 12- through 18-year-old death records (age in completed years) */
base_deaths AS (
    SELECT  dr."Id"               AS death_id,
            dr."Age"              AS age,
            dr."RaceRecode5"      AS race_recode5
    FROM    DEATH.DEATH.DEATHRECORDS dr
    WHERE   dr."Age" BETWEEN 12 AND 18
      AND   dr."AgeType" = 1                -- 1 = years
)

/* Flag each death for vehicle / firearm involvement
   and for whether it is “Black”.                         */
, flagged AS (
    SELECT  b.age,
            /* vehicle flags */
            CASE WHEN vd."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END                              AS vehicle_total,
            CASE WHEN vd."DeathRecordId" IS NOT NULL
                   AND b.race_recode5 IN (SELECT "Code" FROM black_codes) THEN 1 ELSE 0 END         AS vehicle_black,
            /* firearm flags */
            CASE WHEN fd."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END                              AS firearm_total,
            CASE WHEN fd."DeathRecordId" IS NOT NULL
                   AND b.race_recode5 IN (SELECT "Code" FROM black_codes) THEN 1 ELSE 0 END         AS firearm_black
    FROM    base_deaths b
            LEFT JOIN vehicle_deaths vd  ON vd."DeathRecordId" = b.death_id
            LEFT JOIN firearm_deaths fd  ON fd."DeathRecordId" = b.death_id
)

/* Aggregate to age level and ensure every age 12-18 appears */
SELECT  a.age,
        COALESCE(SUM(f.vehicle_total), 0)  AS "vehicle_total_deaths",
        COALESCE(SUM(f.vehicle_black), 0)  AS "vehicle_black_deaths",
        COALESCE(SUM(f.firearm_total), 0)  AS "firearm_total_deaths",
        COALESCE(SUM(f.firearm_black), 0)  AS "firearm_black_deaths"
FROM   ( VALUES (12),(13),(14),(15),(16),(17),(18) ) AS a(age)
       LEFT JOIN flagged f  ON f.age = a.age
GROUP  BY a.age
ORDER BY a.age;