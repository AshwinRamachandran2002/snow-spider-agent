WITH discharge_counts AS (
    /*  White-only deaths whose ICD-10 description contains “discharge”
        (excluding the three unwanted phrases) – count by age-group & code  */
    SELECT
        a."Description"          AS "Age_Group",
        c."Code"                 AS "Icd10Code",
        COUNT(*)                 AS "death_count"
    FROM   DEATH.DEATH.DEATHRECORDS       d
    JOIN   DEATH.DEATH.ICD10CODE          c ON d."Icd10Code"   = c."Code"
    JOIN   DEATH.DEATH.AGERECODE27        a ON d."AgeRecode27" = a."Code"
    WHERE  d."RaceRecode3" = 1                              -- White
      AND  c."Description" ILIKE '%discharge%'
      AND  c."Description" NOT ILIKE '%urethral%discharge%'
      AND  c."Description" NOT ILIKE '%discharge%firework%'
      AND  c."Description" NOT ILIKE '%firearm%discharge%'
    GROUP BY a."Description", c."Code"
),
discharge_avg AS (
    /*  Average deaths per qualifying “discharge” code, by age group  */
    SELECT
        "Age_Group",
        AVG("death_count")       AS "avg_deaths_per_code_discharge"
    FROM   discharge_counts
    GROUP BY "Age_Group"
),
vehicle_counts AS (
    /*  White-only deaths whose ICD-10 description contains “vehicle”
        – count by age-group & code  */
    SELECT
        a."Description"          AS "Age_Group",
        c."Code"                 AS "Icd10Code",
        COUNT(*)                 AS "death_count"
    FROM   DEATH.DEATH.DEATHRECORDS       d
    JOIN   DEATH.DEATH.ICD10CODE          c ON d."Icd10Code"   = c."Code"
    JOIN   DEATH.DEATH.AGERECODE27        a ON d."AgeRecode27" = a."Code"
    WHERE  d."RaceRecode3" = 1                              -- White
      AND  c."Description" ILIKE '%vehicle%'
    GROUP BY a."Description", c."Code"
),
vehicle_avg AS (
    /*  Average deaths per qualifying “vehicle” code, by age group  */
    SELECT
        "Age_Group",
        AVG("death_count")       AS "avg_deaths_per_code_vehicle"
    FROM   vehicle_counts
    GROUP BY "Age_Group"
)
SELECT
    COALESCE(d."Age_Group", v."Age_Group")                       AS "Age_Group",
    d."avg_deaths_per_code_discharge",
    v."avg_deaths_per_code_vehicle",
    /*  How much higher is discharge than vehicle?  */
    d."avg_deaths_per_code_discharge"
    - v."avg_deaths_per_code_vehicle"                            AS "diff_avg_deaths_discharge_minus_vehicle"
FROM   discharge_avg d
FULL JOIN vehicle_avg v
       ON d."Age_Group" = v."Age_Group"
ORDER BY "Age_Group";