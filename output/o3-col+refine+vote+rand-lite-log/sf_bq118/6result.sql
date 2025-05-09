WITH discharge_cte AS (
    SELECT 
        dr."AgeRecode27",
        COUNT(*) AS death_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE    icd
          ON dr."Icd10Code" = icd."Code"
    WHERE dr."RaceRecode3" = 1                                    -- White
      AND LOWER(icd."Description") ILIKE '%discharge%'            -- contains “discharge”
      AND LOWER(icd."Description") NOT ILIKE '%urethral discharge%' 
      AND LOWER(icd."Description") NOT ILIKE '%discharge of firework%'
      AND LOWER(icd."Description") NOT ILIKE '%legal intervention involving firearm discharge%'
    GROUP BY dr."AgeRecode27"
),
vehicle_cte AS (
    SELECT 
        dr."AgeRecode27",
        COUNT(*) AS death_cnt
    FROM DEATH.DEATH.DEATHRECORDS dr
    JOIN DEATH.DEATH.ICD10CODE    icd
          ON dr."Icd10Code" = icd."Code"
    WHERE dr."RaceRecode3" = 1                                    -- White
      AND LOWER(icd."Description") ILIKE '%vehicle%'              -- contains “vehicle”
    GROUP BY dr."AgeRecode27"
),
avg_discharge AS (
    SELECT AVG(death_cnt) AS avg_discharge
    FROM discharge_cte
),
avg_vehicle AS (
    SELECT AVG(death_cnt) AS avg_vehicle
    FROM vehicle_cte
)
SELECT
    ad.avg_discharge                         AS "Avg_Deaths_Discharge",
    av.avg_vehicle                           AS "Avg_Deaths_Vehicle",
    ad.avg_discharge - av.avg_vehicle        AS "Difference_Discharge_vs_Vehicle"   -- positive means discharge > vehicle
FROM avg_discharge ad
CROSS JOIN avg_vehicle av;