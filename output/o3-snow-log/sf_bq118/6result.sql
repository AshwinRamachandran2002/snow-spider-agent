/*---------------------------------------------------------------------------
   Goal:  For WHITE decedents,
          1) Aggregate the number of deaths by AGE-GROUP (AgeRecode27)
             for two ICD-10 keyword categories:
                • “DISCHARGE”  (contains “discharge” but NOT the three
                  excluded phrases)
                • “VEHICLE”    (contains “vehicle”)
          2) Compute the average (mean) number of deaths across all
             age-groups for each category.
          3) Return both averages and the difference
             (DISCHARGE – VEHICLE).
---------------------------------------------------------------------------*/

WITH icd_categories AS (        -- Identify the two ICD-10 keyword groups
    SELECT
        "Code"                              AS "Icd10Code",
        CASE
            WHEN  LOWER("Description") LIKE '%discharge%'
              AND LOWER("Description") NOT LIKE '%urethral discharge%'
              AND LOWER("Description") NOT LIKE '%discharge of firework%'
              AND LOWER("Description") NOT LIKE
                  '%legal intervention involving firearm discharge%'
                 THEN 'DISCHARGE'
            WHEN  LOWER("Description") LIKE '%vehicle%'
                 THEN 'VEHICLE'
        END                                   AS "Category"
    FROM DEATH.DEATH.ICD10CODE
    WHERE (  LOWER("Description") LIKE '%discharge%'
             AND LOWER("Description") NOT LIKE '%urethral discharge%'
             AND LOWER("Description") NOT LIKE '%discharge of firework%'
             AND LOWER("Description") NOT LIKE
                 '%legal intervention involving firearm discharge%' )
       OR  LOWER("Description") LIKE '%vehicle%'
),

age_cat_counts AS (             -- Death counts by age-group & category
    SELECT
        DR."AgeRecode27",
        IC."Category",
        COUNT(*)                               AS "Death_Count"
    FROM DEATH.DEATH.DEATHRECORDS  DR
    JOIN icd_categories            IC
          ON DR."Icd10Code" = IC."Icd10Code"
    WHERE DR."RaceRecode3" = 1                 -- 1 = White
    GROUP BY
        DR."AgeRecode27",
        IC."Category"
),

pivoted AS (                    -- Put the two keyword counts on one row
    SELECT
        AC."AgeRecode27",
        SUM(CASE WHEN AC."Category" = 'DISCHARGE'
                 THEN AC."Death_Count" ELSE 0 END) AS "Discharge_Deaths",
        SUM(CASE WHEN AC."Category" = 'VEHICLE'
                 THEN AC."Death_Count" ELSE 0 END) AS "Vehicle_Deaths"
    FROM age_cat_counts AC
    GROUP BY AC."AgeRecode27"
),

pivoted_all AS (                -- Include age-groups with zero deaths
    SELECT
        A27."Code"                        AS "AgeRecode27",
        COALESCE(P."Discharge_Deaths", 0) AS "Discharge_Deaths",
        COALESCE(P."Vehicle_Deaths" , 0)  AS "Vehicle_Deaths"
    FROM DEATH.DEATH.AGERECODE27 A27
    LEFT JOIN pivoted P
           ON A27."Code" = P."AgeRecode27"
),

averages AS (                   -- Average deaths across all age-groups
    SELECT
        AVG("Discharge_Deaths")  AS "Avg_Discharge_Deaths",
        AVG("Vehicle_Deaths")    AS "Avg_Vehicle_Deaths"
    FROM pivoted_all
)

SELECT
    "Avg_Discharge_Deaths",
    "Avg_Vehicle_Deaths",
    "Avg_Discharge_Deaths" - "Avg_Vehicle_Deaths"  AS "Difference"
FROM averages;