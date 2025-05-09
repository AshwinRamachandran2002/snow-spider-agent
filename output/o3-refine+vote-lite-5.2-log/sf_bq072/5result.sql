WITH "vehicle" AS (
    SELECT DISTINCT
           dr."Id",
           dr."Age",
           'vehicle'                                   AS "Category",
           r."Description"                             AS "RaceDescription"
    FROM DEATH.DEATH."DEATHRECORDS"           dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS"   eac  ON dr."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH."ICD10CODE"              icd  ON eac."Icd10Code" = icd."Code"
    LEFT JOIN DEATH.DEATH."RACE"              r    ON dr."Race"       = r."Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND UPPER(icd."Description") LIKE '%VEHICLE%'
),
"firearm" AS (
    SELECT DISTINCT
           dr."Id",
           dr."Age",
           'firearm'                                   AS "Category",
           r."Description"                             AS "RaceDescription"
    FROM DEATH.DEATH."DEATHRECORDS"           dr
    JOIN DEATH.DEATH."ENTITYAXISCONDITIONS"   eac  ON dr."Id" = eac."DeathRecordId"
    JOIN DEATH.DEATH."ICD10CODE"              icd  ON eac."Icd10Code" = icd."Code"
    LEFT JOIN DEATH.DEATH."RACE"              r    ON dr."Race"       = r."Code"
    WHERE dr."Age" BETWEEN 12 AND 18
      AND UPPER(icd."Description") LIKE '%FIREARM%'
),
"all_rel" AS (
    SELECT * FROM "vehicle"
    UNION ALL
    SELECT * FROM "firearm"
)
SELECT
       "Age",
       "Category",
       COUNT(*)                                                        AS "TotalDeaths",
       SUM(CASE WHEN UPPER("RaceDescription") LIKE '%BLACK%' THEN 1 ELSE 0 END) AS "BlackDeaths"
FROM "all_rel"
GROUP BY
       "Age",
       "Category"
ORDER BY
       "Age",
       "Category";