SELECT dr."Age", 
    COUNT(DISTINCT CASE WHEN icd."Description" ILIKE '%vehicle%' THEN dr."Id" END) AS TotalDeaths_Vehicle,
    COUNT(DISTINCT CASE WHEN icd."Description" ILIKE '%vehicle%' AND r."Description" ILIKE '%black%' THEN dr."Id" END) AS BlackDeaths_Vehicle,
    COUNT(DISTINCT CASE WHEN icd."Description" ILIKE '%firearm%' THEN dr."Id" END) AS TotalDeaths_Firearm,
    COUNT(DISTINCT CASE WHEN icd."Description" ILIKE '%firearm%' AND r."Description" ILIKE '%black%' THEN dr."Id" END) AS BlackDeaths_Firearm
FROM "DEATH"."DEATH"."DEATHRECORDS" dr
JOIN "DEATH"."DEATH"."ENTITYAXISCONDITIONS" eac ON dr."Id" = eac."DeathRecordId"
JOIN "DEATH"."DEATH"."ICD10CODE" icd ON eac."Icd10Code" = icd."Code"
JOIN "DEATH"."DEATH"."RACE" r ON dr."Race" = r."Code"
WHERE dr."Age" BETWEEN 12 AND 18
GROUP BY dr."Age"
ORDER BY dr."Age";