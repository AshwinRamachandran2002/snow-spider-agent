SELECT 
       d."Age" AS "Age_Years",

       /* deaths that involve at least one ICD-10 code whose description contains ‘vehicle’ */
       COUNT(DISTINCT CASE 
                          WHEN i."Description" ILIKE '%vehicle%' 
                          THEN d."Id" 
                     END)                                            AS "Total_Vehicle_Deaths",

       /* of those vehicle deaths, decedents whose race description contains ‘black’ */
       COUNT(DISTINCT CASE 
                          WHEN i."Description" ILIKE '%vehicle%' 
                           AND r."Description" ILIKE '%black%' 
                          THEN d."Id" 
                     END)                                            AS "Black_Vehicle_Deaths",

       /* deaths that involve at least one ICD-10 code whose description contains ‘firearm’ */
       COUNT(DISTINCT CASE 
                          WHEN i."Description" ILIKE '%firearm%' 
                          THEN d."Id" 
                     END)                                            AS "Total_Firearm_Deaths",

       /* of those firearm deaths, decedents whose race description contains ‘black’ */
       COUNT(DISTINCT CASE 
                          WHEN i."Description" ILIKE '%firearm%' 
                           AND r."Description" ILIKE '%black%' 
                          THEN d."Id" 
                     END)                                            AS "Black_Firearm_Deaths"

FROM   DEATH.DEATH.ENTITYAXISCONDITIONS        e
JOIN   DEATH.DEATH.ICD10CODE                   i  ON i."Code" = e."Icd10Code"
JOIN   DEATH.DEATH.DEATHRECORDS               d  ON d."Id"   = e."DeathRecordId"
LEFT   JOIN DEATH.DEATH.RACE                  r  ON r."Code" = d."Race"
WHERE  d."AgeType" = 1                      -- age reported in years
  AND  d."Age" BETWEEN 12 AND 18           -- ages 12-18 inclusive
  AND (i."Description" ILIKE '%vehicle%'    -- keep only rows relevant to either category
       OR i."Description" ILIKE '%firearm%')
GROUP BY d."Age"
ORDER BY d."Age";