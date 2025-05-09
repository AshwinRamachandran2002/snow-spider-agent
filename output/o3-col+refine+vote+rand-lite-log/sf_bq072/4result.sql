WITH vehicle_deaths AS (   -- deaths whose ICD-10 description contains “vehicle”
    SELECT DISTINCT dr."Id"                       AS death_id,
           dr."Age",
           dr."RaceRecode5"
    FROM   DEATH.DEATH.DEATHRECORDS        dr
    JOIN   DEATH.DEATH.ENTITYAXISCONDITIONS eac  ON eac."DeathRecordId" = dr."Id"
    JOIN   DEATH.DEATH.ICD10CODE           icd  ON icd."Code" = eac."Icd10Code"
    WHERE  icd."Description" ILIKE '%vehicle%'
      AND  dr."Age" BETWEEN 12 AND 18
),
firearm_deaths AS (        -- deaths whose ICD-10 description contains “firearm”
    SELECT DISTINCT dr."Id"                       AS death_id,
           dr."Age",
           dr."RaceRecode5"
    FROM   DEATH.DEATH.DEATHRECORDS        dr
    JOIN   DEATH.DEATH.ENTITYAXISCONDITIONS eac  ON eac."DeathRecordId" = dr."Id"
    JOIN   DEATH.DEATH.ICD10CODE           icd  ON icd."Code" = eac."Icd10Code"
    WHERE  icd."Description" ILIKE '%firearm%'
      AND  dr."Age" BETWEEN 12 AND 18
),
vehicle_counts AS (
    SELECT  v."Age",
            COUNT(*)                                               AS total_deaths_vehicle,
            COUNT_IF(rr."Description" ILIKE '%black%')             AS black_deaths_vehicle
    FROM    vehicle_deaths                v
    LEFT JOIN DEATH.DEATH.RACERECODE5 rr  ON rr."Code" = v."RaceRecode5"
    GROUP BY v."Age"
),
firearm_counts AS (
    SELECT  f."Age",
            COUNT(*)                                               AS total_deaths_firearm,
            COUNT_IF(rr."Description" ILIKE '%black%')             AS black_deaths_firearm
    FROM    firearm_deaths                f
    LEFT JOIN DEATH.DEATH.RACERECODE5 rr  ON rr."Code" = f."RaceRecode5"
    GROUP BY f."Age"
),
age_range AS (              -- guarantee a row for every age 12-18
    SELECT 12 AS "Age" UNION ALL SELECT 13 UNION ALL SELECT 14
    UNION ALL SELECT 15 UNION ALL SELECT 16 UNION ALL SELECT 17 UNION ALL
    SELECT 18
)
SELECT ar."Age",
       COALESCE(vc.total_deaths_vehicle ,0)  AS total_deaths_vehicle,
       COALESCE(vc.black_deaths_vehicle ,0)  AS black_deaths_vehicle,
       COALESCE(fc.total_deaths_firearm ,0)  AS total_deaths_firearm,
       COALESCE(fc.black_deaths_firearm ,0)  AS black_deaths_firearm
FROM   age_range        ar
LEFT   JOIN vehicle_counts vc ON vc."Age" = ar."Age"
LEFT   JOIN firearm_counts fc ON fc."Age" = ar."Age"
ORDER  BY ar."Age";