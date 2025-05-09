/*  Difference between the average number of “discharge‑related”
    and “vehicle‑related” deaths (per ICD‑10 code) among WHITE decedents,
    shown by age‑group (AGERECODE27).
*/
WITH discharge_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%discharge%'
      AND LOWER("Description") NOT LIKE '%urethral discharge%'
      AND LOWER("Description") NOT LIKE '%discharge of firework%'
      AND LOWER("Description") NOT LIKE '%legal intervention involving firearm discharge%'
), 

vehicle_codes AS (
    SELECT "Code"
    FROM DEATH.DEATH.ICD10CODE
    WHERE LOWER("Description") LIKE '%vehicle%'
), 

white_deaths AS (
    SELECT "AgeRecode27",
           "Icd10Code"
    FROM DEATH.DEATH.DEATHRECORDS
    WHERE "RaceRecode3" = 1                      -- 1 = White
), 

/*  Count deaths for every ICD‑10 code within each age group                */
category_counts AS (
      /* Discharge */
      SELECT wd."AgeRecode27"            AS age_code,
             'discharge'                AS category,
             wd."Icd10Code"             AS icd_code,
             COUNT(*)                   AS death_count
      FROM   white_deaths  wd
      JOIN   discharge_codes  dc
             ON wd."Icd10Code" = dc."Code"
      GROUP  BY wd."AgeRecode27", wd."Icd10Code"

      UNION ALL

      /* Vehicle */
      SELECT wd."AgeRecode27"            AS age_code,
             'vehicle'                  AS category,
             wd."Icd10Code"             AS icd_code,
             COUNT(*)                   AS death_count
      FROM   white_deaths  wd
      JOIN   vehicle_codes  vc
             ON wd."Icd10Code" = vc."Code"
      GROUP  BY wd."AgeRecode27", wd."Icd10Code"
), 

/*  Average deaths PER ICD‑10 CODE within each category & age group         */
category_avg AS (
    SELECT age_code,
           category,
           AVG(death_count) AS avg_deaths
    FROM   category_counts
    GROUP  BY age_code, category
), 

discharge_avg AS (
    SELECT age_code, avg_deaths
    FROM   category_avg
    WHERE  category = 'discharge'
), 

vehicle_avg AS (
    SELECT age_code, avg_deaths
    FROM   category_avg
    WHERE  category = 'vehicle'
), 

/*  Combine the two category averages and find the difference               */
combined AS (
    SELECT COALESCE(d.age_code, v.age_code)        AS age_code,
           d.avg_deaths                            AS avg_discharge,
           v.avg_deaths                            AS avg_vehicle,
           (d.avg_deaths - v.avg_deaths)           AS diff_discharge_minus_vehicle
    FROM   discharge_avg d
    FULL   JOIN vehicle_avg v
           ON d.age_code = v.age_code
)

SELECT ag."Description"                       AS "Age_Group",
       combined.avg_discharge                 AS "Avg_Deaths_Discharge",
       combined.avg_vehicle                   AS "Avg_Deaths_Vehicle",
       combined.diff_discharge_minus_vehicle  AS "Discharge_Minus_Vehicle"
FROM   combined
LEFT   JOIN DEATH.DEATH.AGERECODE27  ag
       ON combined.age_code = ag."Code"
ORDER  BY ag."Code";