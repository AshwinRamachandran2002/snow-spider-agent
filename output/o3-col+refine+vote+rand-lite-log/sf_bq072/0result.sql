WITH vehicle_deaths AS (      -- Deaths that involve an ICD-10 description containing “vehicle”
    SELECT DISTINCT e."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS  e
    JOIN DEATH.DEATH.ICD10CODE            i  ON e."Icd10Code" = i."Code"
    WHERE i."Description" ILIKE '%vehicle%'
),
firearm_deaths AS (           -- Deaths that involve an ICD-10 description containing “firearm”
    SELECT DISTINCT e."DeathRecordId"
    FROM DEATH.DEATH.ENTITYAXISCONDITIONS  e
    JOIN DEATH.DEATH.ICD10CODE            i  ON e."Icd10Code" = i."Code"
    WHERE i."Description" ILIKE '%firearm%'
),
vehicle_counts AS (           -- Aggregate vehicle-related deaths, 12-18 years old
    SELECT
        d."Age",
        COUNT(*)                                                     AS "Vehicle_Total_Deaths",
        COUNT(CASE WHEN r5."Description" ILIKE '%black%' THEN 1 END) AS "Vehicle_Black_Deaths"
    FROM DEATH.DEATH.DEATHRECORDS d
    JOIN vehicle_deaths          v  ON d."Id" = v."DeathRecordId"
    JOIN DEATH.DEATH.RACERECODE5 r5 ON d."RaceRecode5" = r5."Code"
    WHERE d."Age" BETWEEN 12 AND 18
    GROUP BY d."Age"
),
firearm_counts AS (           -- Aggregate firearm-related deaths, 12-18 years old
    SELECT
        d."Age",
        COUNT(*)                                                     AS "Firearm_Total_Deaths",
        COUNT(CASE WHEN r5."Description" ILIKE '%black%' THEN 1 END) AS "Firearm_Black_Deaths"
    FROM DEATH.DEATH.DEATHRECORDS d
    JOIN firearm_deaths         f  ON d."Id" = f."DeathRecordId"
    JOIN DEATH.DEATH.RACERECODE5 r5 ON d."RaceRecode5" = r5."Code"
    WHERE d."Age" BETWEEN 12 AND 18
    GROUP BY d."Age"
)
-- Combine both result sets so each age (12-18) appears once with all four requested counts
SELECT
    COALESCE(v."Age", f."Age")                    AS "Age",
    COALESCE(v."Vehicle_Total_Deaths", 0)         AS "Vehicle_Total_Deaths",
    COALESCE(v."Vehicle_Black_Deaths", 0)         AS "Vehicle_Black_Deaths",
    COALESCE(f."Firearm_Total_Deaths", 0)         AS "Firearm_Total_Deaths",
    COALESCE(f."Firearm_Black_Deaths", 0)         AS "Firearm_Black_Deaths"
FROM vehicle_counts v
FULL OUTER JOIN firearm_counts f
       ON v."Age" = f."Age"
ORDER BY "Age";