/*  Deaths of persons aged 12‑18 that involved
    (a) any ICD‑10 code whose description contains “vehicle”
    (b) any ICD‑10 code whose description contains “firearm”

    For every age 12–18 the query returns:
      – total deaths that involved a “vehicle” code
      – deaths in that set whose race description contains “black”
      – total deaths that involved a “firearm” code
      – deaths in that set whose race description contains “black”
*/

WITH
/* list of ages we must report, so that ages with zero deaths still appear */
age_list(age) AS (
    SELECT column1 AS age
    FROM (VALUES (12),(13),(14),(15),(16),(17),(18)) v(column1)
),

/* race codes whose description contains the word “black” */
black_race_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH.RACE
    WHERE LOWER("Description") LIKE '%black%'
),

/* for every death record, set flags if any of its ENTITY‑axis ICD‑10 codes
   has a description containing “vehicle” or “firearm”                    */
death_cause_flags AS (
    SELECT
        e."DeathRecordId",
        MAX(IFF(LOWER(i."Description") LIKE '%vehicle%', 1, 0))  AS vehicle_flag,
        MAX(IFF(LOWER(i."Description") LIKE '%firearm%', 1, 0))  AS firearm_flag
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
    JOIN DEATH.DEATH.ICD10CODE            i ON i."Code" = e."Icd10Code"
    GROUP BY e."DeathRecordId"
),

/* aggregate counts by exact age                                          */
age_cause_summary AS (
    SELECT
        d."Age"                                                         AS age,
        SUM(IFF(f.vehicle_flag = 1, 1, 0))                              AS total_vehicle_deaths,
        SUM(IFF(f.vehicle_flag = 1 AND br."Code" IS NOT NULL, 1, 0))    AS black_vehicle_deaths,
        SUM(IFF(f.firearm_flag = 1, 1, 0))                              AS total_firearm_deaths,
        SUM(IFF(f.firearm_flag = 1 AND br."Code" IS NOT NULL, 1, 0))    AS black_firearm_deaths
    FROM DEATH.DEATH.DEATHRECORDS        d
    JOIN death_cause_flags              f  ON f."DeathRecordId" = d."Id"
    LEFT JOIN black_race_codes          br ON br."Code"       = d."Race"
    /* restrict to persons aged 12‑18 in years                           */
    WHERE d."AgeType" = 1
      AND d."Age" BETWEEN 12 AND 18
      AND (f.vehicle_flag = 1 OR f.firearm_flag = 1)
    GROUP BY d."Age"
)

/* final result: one row per age 12‑18                                    */
SELECT
    al.age,
    COALESCE(acs.total_vehicle_deaths , 0) AS total_vehicle_deaths,
    COALESCE(acs.black_vehicle_deaths , 0) AS black_vehicle_deaths,
    COALESCE(acs.total_firearm_deaths , 0) AS total_firearm_deaths,
    COALESCE(acs.black_firearm_deaths , 0) AS black_firearm_deaths
FROM age_list             al
LEFT JOIN age_cause_summary acs ON acs.age = al.age
ORDER BY al.age;