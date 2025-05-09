WITH categorized_deaths AS (   -- identify whether each death involved a “vehicle” and/or “firearm” ICD‑10 code
    SELECT
        ea."DeathRecordId",
        MAX(CASE WHEN ic."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END) AS "HAS_VEHICLE",
        MAX(CASE WHEN ic."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END) AS "HAS_FIREARM"
    FROM DEATH.DEATH."ENTITYAXISCONDITIONS" ea
    JOIN DEATH.DEATH."ICD10CODE" ic
          ON ic."Code" = ea."Icd10Code"
    GROUP BY ea."DeathRecordId"
)

SELECT
    dr."Age"                                                   AS "AGE",
    /* vehicle‑related deaths */
    SUM(CASE WHEN cd."HAS_VEHICLE" = 1 THEN 1 ELSE 0 END)      AS "TOTAL_VEHICLE_DEATHS",
    SUM(CASE WHEN cd."HAS_VEHICLE" = 1
              AND r."Description" ILIKE '%black%' THEN 1 ELSE 0 END) AS "BLACK_VEHICLE_DEATHS",
    /* firearm‑related deaths */
    SUM(CASE WHEN cd."HAS_FIREARM" = 1 THEN 1 ELSE 0 END)      AS "TOTAL_FIREARM_DEATHS",
    SUM(CASE WHEN cd."HAS_FIREARM" = 1
              AND r."Description" ILIKE '%black%' THEN 1 ELSE 0 END) AS "BLACK_FIREARM_DEATHS"
FROM      DEATH.DEATH."DEATHRECORDS"      dr
JOIN      categorized_deaths              cd  ON cd."DeathRecordId" = dr."Id"
LEFT JOIN DEATH.DEATH."RACE"              r   ON r."Code"           = dr."Race"
WHERE
      dr."AgeType" = 1                     -- restrict to ages expressed in years
  AND dr."Age" BETWEEN 12 AND 18           -- ages 12 through 18 inclusive
GROUP BY
    dr."Age"
ORDER BY
    dr."Age";