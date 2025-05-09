SELECT
    DR."Age",
    COUNT(CASE WHEN I."Description" ILIKE '%vehicle%' THEN 1 END) AS "Total_Deaths_Vehicle",
    COUNT(CASE WHEN I."Description" ILIKE '%vehicle%' AND R."Code" = 2 THEN 1 END) AS "Black_Deaths_Vehicle",
    COUNT(CASE WHEN I."Description" ILIKE '%firearm%' THEN 1 END) AS "Total_Deaths_Firearms",
    COUNT(CASE WHEN I."Description" ILIKE '%firearm%' AND R."Code" = 2 THEN 1 END) AS "Black_Deaths_Firearms"
FROM DEATH.DEATH.DEATHRECORDS DR
JOIN DEATH.DEATH.ICD10CODE I ON DR."Icd10Code" = I."Code"
JOIN DEATH.DEATH.RACE R ON DR."Race" = R."Code"
WHERE DR."Age" BETWEEN 12 AND 18
GROUP BY DR."Age"
ORDER BY DR."Age";