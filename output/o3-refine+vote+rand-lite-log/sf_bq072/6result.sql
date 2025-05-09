WITH vehicle_ids AS (
    /* Deaths that involve at least one ICD‑10 code whose description contains “vehicle” */
    SELECT DISTINCT
           EA."DeathRecordId"
    FROM   DEATH.DEATH.ENTITYAXISCONDITIONS  EA
           JOIN DEATH.DEATH.ICD10CODE        IC
             ON IC."Code" = EA."Icd10Code"
    WHERE  IC."Description" ILIKE '%vehicle%'
),
firearm_ids AS (
    /* Deaths that involve at least one ICD‑10 code whose description contains “firearm” */
    SELECT DISTINCT
           EA."DeathRecordId"
    FROM   DEATH.DEATH.ENTITYAXISCONDITIONS  EA
           JOIN DEATH.DEATH.ICD10CODE        IC
             ON IC."Code" = EA."Icd10Code"
    WHERE  IC."Description" ILIKE '%firearm%'
),
black_race_codes AS (
    /* Race codes whose description contains the word “black” */
    SELECT  "Code" AS race_code
    FROM    DEATH.DEATH.RACE
    WHERE   "Description" ILIKE '%black%'
),
death_base AS (
    /* 12‑18‑year‑old decedents (age expressed in years = AgeType 1) */
    SELECT  DR."Id"    AS death_id,
            DR."Age"   AS age_years,
            DR."Race"  AS race_code
    FROM    DEATH.DEATH.DEATHRECORDS DR
    WHERE   DR."AgeType" = 1
      AND   DR."Age" BETWEEN 12 AND 18
),
death_flags AS (
    /* Flag whether each death is vehicle‑related and/or firearm‑related */
    SELECT  DB.age_years,
            DB.race_code,
            CASE WHEN V."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END AS is_vehicle,
            CASE WHEN F."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END AS is_firearm
    FROM    death_base        DB
            LEFT JOIN vehicle_ids  V ON V."DeathRecordId" = DB.death_id
            LEFT JOIN firearm_ids  F ON F."DeathRecordId" = DB.death_id
)
SELECT  age_years                                                   AS "Age",
        SUM(is_vehicle)                                             AS "Vehicle_Total_Deaths",
        SUM(CASE WHEN is_vehicle = 1
                   AND race_code IN (SELECT race_code FROM black_race_codes)
                 THEN 1 ELSE 0 END)                                 AS "Vehicle_Black_Deaths",
        SUM(is_firearm)                                             AS "Firearm_Total_Deaths",
        SUM(CASE WHEN is_firearm = 1
                   AND race_code IN (SELECT race_code FROM black_race_codes)
                 THEN 1 ELSE 0 END)                                 AS "Firearm_Black_Deaths"
FROM    death_flags
GROUP BY age_years
ORDER BY age_years;