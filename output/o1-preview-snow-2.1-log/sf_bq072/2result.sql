SELECT
    dr."Age",
    SUM(CASE WHEN dr."Icd10Code" IN (
        SELECT "Code"
        FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%vehicle%' OR "Description" ILIKE '%transport%' OR "Description" ILIKE '%motor%'
    ) THEN 1 ELSE 0 END) AS "Total_Deaths_Vehicle",
    SUM(CASE WHEN dr."Icd10Code" IN (
        SELECT "Code"
        FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%vehicle%' OR "Description" ILIKE '%transport%' OR "Description" ILIKE '%motor%'
    ) AND r."Description" ILIKE '%Black%' THEN 1 ELSE 0 END) AS "Black_Deaths_Vehicle",
    SUM(CASE WHEN dr."Icd10Code" IN (
        SELECT "Code"
        FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%firearm%' OR "Description" ILIKE '%gun%' OR "Description" ILIKE '%weapon%'
    ) THEN 1 ELSE 0 END) AS "Total_Deaths_Firearms",
    SUM(CASE WHEN dr."Icd10Code" IN (
        SELECT "Code"
        FROM DEATH.DEATH.ICD10CODE
        WHERE "Description" ILIKE '%firearm%' OR "Description" ILIKE '%gun%' OR "Description" ILIKE '%weapon%'
    ) AND r."Description" ILIKE '%Black%' THEN 1 ELSE 0 END) AS "Black_Deaths_Firearms"
FROM DEATH.DEATH.DEATHRECORDS dr
LEFT JOIN DEATH.DEATH.RACE r ON dr."Race" = r."Code"
WHERE dr."Age" BETWEEN 12 AND 18
GROUP BY dr."Age"
ORDER BY dr."Age";