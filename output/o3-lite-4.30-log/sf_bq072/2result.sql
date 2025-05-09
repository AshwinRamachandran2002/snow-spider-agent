SELECT
    dr."Age"                                                          AS age,
    COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%vehicle%'  THEN dr."Id" END)                                       AS total_vehicle_deaths,
    COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%vehicle%'  AND r."Description" ILIKE '%black%' THEN dr."Id" END)   AS black_vehicle_deaths,
    COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%firearm%'  THEN dr."Id" END)                                       AS total_firearm_deaths,
    COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%firearm%'  AND r."Description" ILIKE '%black%' THEN dr."Id" END)   AS black_firearm_deaths
FROM DEATH.DEATH.DEATHRECORDS          dr
JOIN DEATH.DEATH.ENTITYAXISCONDITIONS  eac  ON dr."Id" = eac."DeathRecordId"
JOIN DEATH.DEATH.ICD10CODE             ic   ON eac."Icd10Code" = ic."Code"
LEFT JOIN DEATH.DEATH.RACE             r    ON dr."Race" = r."Code"
WHERE dr."AgeType" = 1                      -- retain only ages expressed in years
  AND dr."Age" BETWEEN 12 AND 18
GROUP BY dr."Age"
ORDER BY dr."Age";