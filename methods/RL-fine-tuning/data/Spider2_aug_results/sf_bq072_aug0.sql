-- Task: Provide, for each age from 12 to 18 inclusive, a summary that includes:
-- - The total number of deaths where the deceased is aged between 12 and 18 inclusive and is associated with at least one ICD-10 code whose description includes the word ‘vehicle’, and among these deaths, the number of individuals identified as Black (where race descriptions contain the word 'black').
-- - The total number of deaths where the deceased is aged between 12 and 18 inclusive and is associated with at least one ICD-10 code whose description includes the word ‘firearm’, and among these deaths, the number of individuals identified as Black (where race descriptions contain the word 'black').
-- Use the ENTITYAXISCONDITIONS table to determine which ICD-10 codes are involved in each death (i.e., identify the deaths associated with 'vehicle' or 'firearm' codes via this table), and use the RACE table to determine if an individual is identified as Black based on the race description containing the word 'black'.
-- Do not join ICD-10 code information directly on the death records.

WITH BlackRace AS (
    SELECT CAST("Code" AS INT) AS CODE
    FROM DEATH.DEATH.RACE
    WHERE LOWER("Description") LIKE '%black%'
)
SELECT 
    v."Age", 
    v."Total" AS "Vehicle_Total", 
    v."Black" AS "Vehicle_Black",
    g."Total" AS "Gun_Total", 
    g."Black" AS "Gun_Black"
FROM (
    SELECT 
        "Age", 
        COUNT(*) AS "Total", 
        COUNT_IF("Race" IN (SELECT CODE FROM BlackRace)) AS "Black"
    FROM DEATH.DEATH.DEATHRECORDS d
    JOIN (
        SELECT 
            DISTINCT e."DeathRecordId" AS "id"
        FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
        JOIN (
            SELECT * 
            FROM DEATH.DEATH.ICD10CODE 
            WHERE LOWER("Description") LIKE '%vehicle%'
        ) c 
        ON e."Icd10Code" = c."Code"
    ) f
    ON d."Id" = f."id"
    WHERE "Age" BETWEEN 12 AND 18
    GROUP BY "Age"
) v  -- Vehicle

JOIN (
    SELECT 
        "Age", 
        COUNT(*) AS "Total", 
        COUNT_IF("Race" IN (SELECT CODE FROM BlackRace)) AS "Black"
    FROM DEATH.DEATH.DEATHRECORDS d
    JOIN (
        SELECT 
            DISTINCT e."DeathRecordId" AS "id"
        FROM DEATH.DEATH.ENTITYAXISCONDITIONS e
        JOIN (
            SELECT 
                "Code", "Description" 
            FROM DEATH.DEATH.ICD10CODE
            WHERE "Description" LIKE '%firearm%'
        ) c 
        ON e."Icd10Code" = c."Code"
    ) f
    ON d."Id" = f."id"
    WHERE "Age" BETWEEN 12 AND 18
    GROUP BY "Age"
) g
ON g."Age" = v."Age";