-- Task: Please provide, for each age from 12 through 18 (inclusive), the total number of deaths and the number of deaths among individuals identified as Black (based on race descriptions containing the word 'black'), specifically for deaths associated with ICD-10 codes whose descriptions include the word 'vehicle.' Use the EntityAxisConditions table to determine which ICD-10 codes were involved in each death, rather than joining ICD-10 code information directly on the death records.

WITH BlackRace AS (
    SELECT CAST("Code" AS INT) AS CODE
    FROM DEATH.DEATH.RACE
    WHERE LOWER("Description") LIKE '%black%'
)
SELECT 
    d."Age", 
    COUNT(*) AS "Total", 
    COUNT_IF(d."Race" IN (SELECT CODE FROM BlackRace)) AS "Black"
FROM DEATH.DEATH.DEATHRECORDS d
JOIN (
    SELECT DISTINCT e."DeathRecordId" AS "id"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
    JOIN (
        SELECT "Code"
        FROM DEATH.DEATH.ICD10CODE 
        WHERE LOWER("Description") LIKE '%vehicle%'
    ) c 
    ON e."Icd10Code" = c."Code"
) f
ON d."Id" = f."id"
WHERE d."Age" BETWEEN 12 AND 18
GROUP BY d."Age";