WITH white_records AS (       -- all death records for White individuals
    SELECT 
        "Id",
        "Icd10Code",
        "AgeRecode27"
    FROM DEATH.DEATH.DEATHRECORDS
    WHERE "RaceRecode3" = 1                               -- 1 = White
),

/*=================================================================
  DISCHARGE-RELATED ICD-10 CODES  (exclude the three unwanted ones)
==================================================================*/
discharge_code_counts AS ( 
    SELECT 
        wr."AgeRecode27",
        wr."Icd10Code",
        COUNT(*) AS death_cnt
    FROM white_records wr
    JOIN DEATH.DEATH.ICD10CODE icd
          ON icd."Code" = wr."Icd10Code"
    WHERE LOWER(icd."Description") LIKE '%discharge%'             -- contains “discharge”
      AND LOWER(icd."Description") NOT LIKE 'urethral discharge%' -- exclude
      AND LOWER(icd."Description") NOT LIKE '%discharge of firework%'
      AND LOWER(icd."Description") NOT LIKE '%legal intervention involving firearm discharge%'
    GROUP BY wr."AgeRecode27", wr."Icd10Code"
),

avg_discharge AS (            -- average deaths per discharge-related ICD code
    SELECT
        "AgeRecode27",
        AVG(death_cnt) AS avg_deaths_discharge
    FROM discharge_code_counts
    GROUP BY "AgeRecode27"
),

/*=================================================================
  VEHICLE-RELATED ICD-10 CODES
==================================================================*/
vehicle_code_counts AS (
    SELECT 
        wr."AgeRecode27",
        wr."Icd10Code",
        COUNT(*) AS death_cnt
    FROM white_records wr
    JOIN DEATH.DEATH.ICD10CODE icd
          ON icd."Code" = wr."Icd10Code"
    WHERE LOWER(icd."Description") LIKE '%vehicle%'               -- contains “vehicle”
    GROUP BY wr."AgeRecode27", wr."Icd10Code"
),

avg_vehicle AS (              -- average deaths per vehicle-related ICD code
    SELECT
        "AgeRecode27",
        AVG(death_cnt) AS avg_deaths_vehicle
    FROM vehicle_code_counts
    GROUP BY "AgeRecode27"
)

/*=================================================================
  FINAL RESULT  – difference (discharge – vehicle) by age group
==================================================================*/
SELECT 
    ar27."Description"                              AS age_group,
    COALESCE(ad.avg_deaths_discharge, 0)            AS avg_deaths_discharge,
    COALESCE(av.avg_deaths_vehicle,   0)            AS avg_deaths_vehicle,
    COALESCE(ad.avg_deaths_discharge, 0) 
      - COALESCE(av.avg_deaths_vehicle,   0)        AS diff_avg_deaths
FROM DEATH.DEATH.AGERECODE27 ar27
LEFT JOIN avg_discharge ad  ON ad."AgeRecode27" = ar27."Code"
LEFT JOIN avg_vehicle   av  ON av."AgeRecode27" = ar27."Code"
WHERE ad.avg_deaths_discharge IS NOT NULL 
   OR av.avg_deaths_vehicle   IS NOT NULL          -- keep only groups with data
ORDER BY ar27."Code";