SELECT
    d."Age" AS "age",
    COUNT(DISTINCT CASE WHEN i."Description" ILIKE '%vehicle%'  THEN d."Id" END)                                             AS "total_vehicle_deaths",
    COUNT(DISTINCT CASE WHEN i."Description" ILIKE '%vehicle%'  AND r."Description" ILIKE '%black%' THEN d."Id" END)         AS "black_vehicle_deaths",
    COUNT(DISTINCT CASE WHEN i."Description" ILIKE '%firearm%' THEN d."Id" END)                                             AS "total_firearm_deaths",
    COUNT(DISTINCT CASE WHEN i."Description" ILIKE '%firearm%' AND r."Description" ILIKE '%black%' THEN d."Id" END)         AS "black_firearm_deaths"
FROM DEATH.DEATH.DEATHRECORDS         d
JOIN DEATH.DEATH.ENTITYAXISCONDITIONS e  ON d."Id" = e."DeathRecordId"
JOIN DEATH.DEATH.ICD10CODE            i  ON e."Icd10Code" = i."Code"
LEFT JOIN DEATH.DEATH.RACE            r  ON d."Race" = r."Code"
WHERE d."Age" BETWEEN 12 AND 18
  AND (i."Description" ILIKE '%vehicle%' OR i."Description" ILIKE '%firearm%')
GROUP BY d."Age"
ORDER BY d."Age";