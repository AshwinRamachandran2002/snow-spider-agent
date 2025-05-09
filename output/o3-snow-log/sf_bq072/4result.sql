WITH
/* 1.  Deaths that involve at least one ICD-10 code whose description contains the word “vehicle”           */
"VEHICLE_DEATHS" AS (
    SELECT DISTINCT E."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS  E
    JOIN DEATH.DEATH.ICD10CODE             I
          ON E."Icd10Code" = I."Code"
    WHERE LOWER(I."Description") LIKE '%vehicle%'
),
/* 2.  Deaths that involve at least one ICD-10 code whose description contains the word “firearm”           */
"FIREARM_DEATHS" AS (
    SELECT DISTINCT E."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS  E
    JOIN DEATH.DEATH.ICD10CODE             I
          ON E."Icd10Code" = I."Code"
    WHERE LOWER(I."Description") LIKE '%firearm%'
),
/* 3.  Codes in the RACE table whose description contains the word “black” (case-insensitive)               */
"BLACK_RACE_CODES" AS (
    SELECT "Code" AS "RaceCode"
    FROM   DEATH.DEATH.RACE
    WHERE  LOWER("Description") LIKE '%black%'
)

/* 4.  Aggregate the requested statistics for ages 12–18                                                    */
SELECT
       DR."Age"                                                         AS "Age",
       /* Vehicle–related deaths */
       SUM(CASE WHEN VD."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END)  AS "Vehicle_Total",
       SUM(CASE WHEN VD."DeathRecordId" IS NOT NULL
                 AND DR."Race" IN (SELECT "RaceCode" FROM "BLACK_RACE_CODES")
                THEN 1 ELSE 0 END)                                      AS "Vehicle_Black",
       /* Firearm–related deaths */
       SUM(CASE WHEN FD."DeathRecordId" IS NOT NULL THEN 1 ELSE 0 END)  AS "Firearm_Total",
       SUM(CASE WHEN FD."DeathRecordId" IS NOT NULL
                 AND DR."Race" IN (SELECT "RaceCode" FROM "BLACK_RACE_CODES")
                THEN 1 ELSE 0 END)                                      AS "Firearm_Black"
FROM   DEATH.DEATH.DEATHRECORDS              DR
LEFT JOIN "VEHICLE_DEATHS"                   VD ON VD."DeathRecordId" = DR."Id"
LEFT JOIN "FIREARM_DEATHS"                   FD ON FD."DeathRecordId" = DR."Id"
WHERE  DR."AgeType" = 1                -- Age reported in years
  AND  DR."Age" BETWEEN 12 AND 18       -- Ages 12 through 18 inclusive
GROUP BY DR."Age"
ORDER BY DR."Age";