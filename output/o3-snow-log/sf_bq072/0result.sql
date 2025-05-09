/*  Vehicle- and Firearm-related deaths among 12- to 18-year-olds,
    showing totals and counts for decedents whose race description
    contains the word “black”.
*/
WITH code_flags AS (          -- flag each death for VEHICLE / FIREARM involvement
    SELECT
        EA."DeathRecordId",
        MAX(CASE WHEN UPPER(IC."Description") LIKE '%VEHICLE%' THEN 1 ELSE 0 END) AS has_vehicle,
        MAX(CASE WHEN UPPER(IC."Description") LIKE '%FIREARM%' THEN 1 ELSE 0 END)  AS has_firearm
    FROM DEATH.DEATH."ENTITYAXISCONDITIONS"  EA
    JOIN DEATH.DEATH."ICD10CODE"              IC
          ON EA."Icd10Code" = IC."Code"
    GROUP BY EA."DeathRecordId"
),
black_race_codes AS (         -- codes whose race description contains “black”
    SELECT "Code"
    FROM DEATH.DEATH."RACE"
    WHERE UPPER("Description") LIKE '%BLACK%'
),
deaths_12_18 AS (             -- deaths of 12- to 18-year-olds with the flags
    SELECT
        DR."Id"      AS death_id,
        DR."Age"     AS age_years,
        DR."Race"    AS race_code,
        CF.has_vehicle,
        CF.has_firearm
    FROM DEATH.DEATH."DEATHRECORDS" DR
    JOIN code_flags CF
          ON DR."Id" = CF."DeathRecordId"
    WHERE DR."Age" BETWEEN 12 AND 18
          AND DR."AgeType" = 1            -- 1 = years (omit if not applicable)
)
SELECT
    age_years                                            AS "AGE",
    COUNT(DISTINCT CASE WHEN has_vehicle = 1 THEN death_id END)                                                    AS "VEHICLE_TOTAL_DEATHS",
    COUNT(DISTINCT CASE WHEN has_vehicle = 1 AND race_code IN (SELECT "Code" FROM black_race_codes) THEN death_id END) AS "VEHICLE_BLACK_DEATHS",
    COUNT(DISTINCT CASE WHEN has_firearm = 1 THEN death_id END)                                                     AS "FIREARM_TOTAL_DEATHS",
    COUNT(DISTINCT CASE WHEN has_firearm = 1 AND race_code IN (SELECT "Code" FROM black_race_codes) THEN death_id END) AS "FIREARM_BLACK_DEATHS"
FROM deaths_12_18
GROUP BY age_years
ORDER BY age_years;