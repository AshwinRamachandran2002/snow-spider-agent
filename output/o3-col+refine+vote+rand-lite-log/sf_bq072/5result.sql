WITH "CATEGORY_DEATHS" AS (
    /* deaths that involve at least one ICD-10 code whose description contains “vehicle” */
    SELECT DISTINCT 
           ea."DeathRecordId",
           'vehicle' AS "Category"
    FROM   DEATH.DEATH."ENTITYAXISCONDITIONS" ea
    JOIN   DEATH.DEATH."ICD10CODE"            ic
           ON ea."Icd10Code" = ic."Code"
    WHERE  ic."Description" ILIKE '%vehicle%'

    UNION ALL

    /* deaths that involve at least one ICD-10 code whose description contains “firearm” */
    SELECT DISTINCT 
           ea."DeathRecordId",
           'firearm' AS "Category"
    FROM   DEATH.DEATH."ENTITYAXISCONDITIONS" ea
    JOIN   DEATH.DEATH."ICD10CODE"            ic
           ON ea."Icd10Code" = ic."Code"
    WHERE  ic."Description" ILIKE '%firearm%'
)

SELECT
       dr."Age"                                            AS "Age",
       cd."Category"                                       AS "Category",
       COUNT(*)                                            AS "TotalDeaths",
       SUM(CASE WHEN r."Description" ILIKE '%black%' 
                THEN 1 ELSE 0 END)                         AS "BlackDeaths"
FROM   "CATEGORY_DEATHS"            cd
JOIN   DEATH.DEATH."DEATHRECORDS"  dr  ON cd."DeathRecordId" = dr."Id"
JOIN   DEATH.DEATH."RACE"          r   ON dr."Race"         = r."Code"
WHERE  dr."AgeType" = 1                 -- age is reported in years
  AND  dr."Age" BETWEEN 12 AND 18       -- ages 12 through 18 inclusive
GROUP  BY dr."Age", cd."Category"
ORDER  BY dr."Age", cd."Category";