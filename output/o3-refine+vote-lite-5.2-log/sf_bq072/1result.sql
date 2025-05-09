WITH
    race_black AS (          -- race codes whose description contains “black”
        SELECT "Code"
        FROM DEATH.DEATH.RACE
        WHERE LOWER("Description") LIKE '%black%'
    ),

    vehicle_deaths AS (      -- deaths with at least one ICD‑10 description containing “vehicle”
        SELECT DISTINCT EC."DeathRecordId"
        FROM DEATH.DEATH.ENTITYAXISCONDITIONS   EC
        JOIN DEATH.DEATH.ICD10CODE              IC
              ON IC."Code" = EC."Icd10Code"
        WHERE LOWER(IC."Description") LIKE '%vehicle%'
    ),

    firearm_deaths AS (      -- deaths with at least one ICD‑10 description containing “firearm”
        SELECT DISTINCT EC."DeathRecordId"
        FROM DEATH.DEATH.ENTITYAXISCONDITIONS   EC
        JOIN DEATH.DEATH.ICD10CODE              IC
              ON IC."Code" = EC."Icd10Code"
        WHERE LOWER(IC."Description") LIKE '%firearm%'
    ),

    deaths_union AS (        -- combine the two cause categories
        SELECT "DeathRecordId", 'vehicle' AS "CauseCategory" FROM vehicle_deaths
        UNION ALL
        SELECT "DeathRecordId", 'firearm' AS "CauseCategory" FROM firearm_deaths
    )

SELECT
    DR."Age"                                         AS "Age",
    DU."CauseCategory"                               AS "Cause_Category",
    COUNT(*)                                         AS "Total_Deaths",
    SUM(CASE WHEN DR."Race" IN (SELECT "Code" FROM race_black)
             THEN 1 ELSE 0 END)                      AS "Black_Deaths"
FROM deaths_union             DU
JOIN DEATH.DEATH.DEATHRECORDS DR
     ON DR."Id" = DU."DeathRecordId"
WHERE DR."AgeType" = 1               -- age recorded in years
  AND DR."Age" BETWEEN 12 AND 18     -- ages 12‑18 inclusive
GROUP BY
    DR."Age",
    DU."CauseCategory"
ORDER BY
    DR."Age",
    DU."CauseCategory";