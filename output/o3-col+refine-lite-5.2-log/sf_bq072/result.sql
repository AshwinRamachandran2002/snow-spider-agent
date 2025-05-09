SELECT
        dr."Age"                                                                         AS "Age",
        COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%vehicle%'  THEN dr."Id" END)   AS "Total_Vehicle_Deaths",
        COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%vehicle%'  AND r."Description" ILIKE '%black%' THEN dr."Id" END)
                                                                                            AS "Black_Vehicle_Deaths",
        COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%firearm%'  THEN dr."Id" END)   AS "Total_Firearm_Deaths",
        COUNT(DISTINCT CASE WHEN ic."Description" ILIKE '%firearm%'  AND r."Description" ILIKE '%black%' THEN dr."Id" END)
                                                                                            AS "Black_Firearm_Deaths"
FROM    DEATH.DEATH.DEATHRECORDS         dr
JOIN    DEATH.DEATH.ENTITYAXISCONDITIONS eac  ON dr."Id" = eac."DeathRecordId"
JOIN    DEATH.DEATH.ICD10CODE            ic   ON eac."Icd10Code" = ic."Code"
LEFT JOIN DEATH.DEATH.RACE               r    ON dr."Race" = r."Code"
WHERE   dr."Age" BETWEEN 12 AND 18
GROUP BY dr."Age"
ORDER BY dr."Age";