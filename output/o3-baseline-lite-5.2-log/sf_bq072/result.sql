WITH categorized_deaths AS (      -- death records that mention “vehicle” or “firearm” in ANY entity‑axis ICD‑10 code
    SELECT DISTINCT
           e."DeathRecordId"                           AS "DeathRecordId",
           CASE
               WHEN ic."Description" ILIKE '%vehicle%' THEN 'VEHICLE'
               WHEN ic."Description" ILIKE '%firearm%' THEN 'FIREARM'
           END                                         AS "Category"
    FROM DEATH.DEATH."ENTITYAXISCONDITIONS" e
    JOIN DEATH.DEATH."ICD10CODE"        ic
      ON ic."Code" = e."Icd10Code"
    WHERE ic."Description" ILIKE '%vehicle%'
       OR ic."Description" ILIKE '%firearm%'
), deaths_with_info AS (          -- bring in age and race information
    SELECT
           cd."Category",
           d."Age"                                 AS "Age",
           (r."Description" ILIKE '%black%')       AS "IsBlack",
           d."Id"                                  AS "DeathRecordId"
    FROM categorized_deaths        cd
    JOIN DEATH.DEATH."DEATHRECORDS" d
      ON d."Id" = cd."DeathRecordId"
    LEFT JOIN DEATH.DEATH."RACE"   r
      ON r."Code" = d."Race"
    WHERE d."Age" BETWEEN 12 AND 18               -- only ages 12–18
      AND (d."AgeType" = 1 OR d."AgeType" IS NULL) -- AgeType 1 = years
)
SELECT
       "Age",
       "Category",
       COUNT("DeathRecordId")                           AS "TotalDeaths",
       COUNT_IF("IsBlack")                              AS "BlackDeaths"
FROM deaths_with_info
GROUP BY "Age", "Category"
ORDER BY "Age", "Category";