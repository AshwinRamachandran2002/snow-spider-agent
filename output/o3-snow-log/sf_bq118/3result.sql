WITH category_codes AS (   -- ICD-10 codes of interest
    /* 1.  Codes whose description contains “discharge” (but exclude three specific phrases) */
    SELECT "Code" AS "Icd10Code" , 'Discharge' AS "Category"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%discharge%'
      AND  LOWER("Description") NOT LIKE '%urethral discharge%'
      AND  LOWER("Description") NOT LIKE '%discharge of firework%'
      AND  LOWER("Description") NOT LIKE '%legal intervention involving firearm discharge%'

    UNION ALL

    /* 2.  Codes whose description contains “vehicle” */
    SELECT "Code" AS "Icd10Code" , 'Vehicle' AS "Category"
    FROM   DEATH.DEATH.ICD10CODE
    WHERE  LOWER("Description") LIKE '%vehicle%'
),

white_death_records AS (   -- deaths of White individuals
    SELECT dr."AgeRecode27",
           dr."Icd10Code"
    FROM   DEATH.DEATH.DEATHRECORDS dr
    WHERE  dr."RaceRecode3" = 1          -- 1 = White in RACERECODE3
),

deaths_with_category AS (  -- keep only deaths whose ICD-10 code is in either category
    SELECT wdr."AgeRecode27",
           cc."Category",
           wdr."Icd10Code"
    FROM   white_death_records wdr
    JOIN   category_codes     cc
           ON wdr."Icd10Code" = cc."Icd10Code"
),

deaths_per_code AS (       -- number of deaths for each ICD-10 code within each age group & category
    SELECT d."AgeRecode27",
           d."Category",
           d."Icd10Code",
           COUNT(*) AS "Death_Count"
    FROM   deaths_with_category d
    GROUP  BY d."AgeRecode27", d."Category", d."Icd10Code"
),

average_deaths AS (        -- average deaths per ICD-10 code inside each age group & category
    SELECT dc."AgeRecode27",
           ar."Description"                    AS "Age_Group",
           dc."Category",
           AVG(dc."Death_Count")               AS "Avg_Deaths"
    FROM   deaths_per_code          dc
    JOIN   DEATH.DEATH.AGERECODE27  ar
           ON dc."AgeRecode27" = ar."Code"
    GROUP  BY dc."AgeRecode27", ar."Description", dc."Category"
),

pivoted AS (               -- put “discharge” & “vehicle” averages on the same row
    SELECT "AgeRecode27",
           "Age_Group",
           MAX(CASE WHEN "Category" = 'Discharge' THEN "Avg_Deaths" END) AS "Discharge_Avg",
           MAX(CASE WHEN "Category" = 'Vehicle'   THEN "Avg_Deaths" END) AS "Vehicle_Avg"
    FROM   average_deaths
    GROUP  BY "AgeRecode27", "Age_Group"
)

SELECT  "Age_Group",
        "Discharge_Avg" - "Vehicle_Avg" AS "Difference_In_Average_Deaths"
FROM    pivoted
ORDER BY "AgeRecode27";