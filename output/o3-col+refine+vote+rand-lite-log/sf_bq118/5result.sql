WITH age_groups AS (      -- full list of 12 standard age–recode groups
    SELECT DISTINCT
           "Code" AS "AgeRecode12"
    FROM   DEATH.DEATH."AGERECODE12"
),

-- deaths whose ICD-10 description contains “discharge”, after exclusions
discharge_counts AS (
    SELECT 
        dr."AgeRecode12",
        COUNT(*) AS discharge_deaths
    FROM   DEATH.DEATH."DEATHRECORDS" dr
    JOIN   DEATH.DEATH."ICD10CODE"    ic
           ON ic."Code" = dr."Icd10Code"
    WHERE  dr."RaceRecode3" = 1                              -- White
      AND  ic."Description" ILIKE '%discharge%'
      AND  ic."Description" NOT ILIKE '%urethral discharge%'
      AND  ic."Description" NOT ILIKE '%discharge of firework%'
      AND  ic."Description" NOT ILIKE '%legal intervention involving firearm discharge%'
    GROUP  BY dr."AgeRecode12"
),

-- deaths whose ICD-10 description contains “vehicle”
vehicle_counts AS (
    SELECT 
        dr."AgeRecode12",
        COUNT(*) AS vehicle_deaths
    FROM   DEATH.DEATH."DEATHRECORDS" dr
    JOIN   DEATH.DEATH."ICD10CODE"    ic
           ON ic."Code" = dr."Icd10Code"
    WHERE  dr."RaceRecode3" = 1                              -- White
      AND  ic."Description" ILIKE '%vehicle%'
    GROUP  BY dr."AgeRecode12"
),

-- bring both series onto the same age-group frame
combined AS (
    SELECT 
        ag."AgeRecode12",
        COALESCE(dc.discharge_deaths, 0) AS discharge_deaths,
        COALESCE(vc.vehicle_deaths,   0) AS vehicle_deaths
    FROM   age_groups      ag
    LEFT   JOIN discharge_counts dc ON dc."AgeRecode12" = ag."AgeRecode12"
    LEFT   JOIN vehicle_counts  vc ON vc."AgeRecode12" = ag."AgeRecode12"
)

-- compute the average deaths per age group and the difference
SELECT 
    AVG(discharge_deaths)                             AS "Avg_Discharge_Deaths",
    AVG(vehicle_deaths)                               AS "Avg_Vehicle_Deaths",
    AVG(discharge_deaths) - AVG(vehicle_deaths)       AS "Difference"
FROM   combined;