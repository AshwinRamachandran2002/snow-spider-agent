SELECT dr."Age",
       SUM(CASE WHEN ic."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END) AS "Total_Deaths_Vehicle",
       SUM(CASE WHEN dr."Race" = 2 AND ic."Description" ILIKE '%vehicle%' THEN 1 ELSE 0 END) AS "Black_Deaths_Vehicle",
       SUM(CASE WHEN ic."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END) AS "Total_Deaths_Firearms",
       SUM(CASE WHEN dr."Race" = 2 AND ic."Description" ILIKE '%firearm%' THEN 1 ELSE 0 END) AS "Black_Deaths_Firearms"
FROM DEATH.DEATH.DEATHRECORDS dr
JOIN DEATH.DEATH.ICD10CODE ic ON dr."Icd10Code" = ic."Code"
WHERE dr."Age" BETWEEN 12 AND 18
GROUP BY dr."Age"
ORDER BY dr."Age";