/*---------------------------------------------------------------------
  Among WHITE (RaceRecode3 = 1) decedents, compare deaths whose ICD-10
  descriptions contain the word “discharge” (excluding the three
  specified phrases) with those that contain the word “vehicle”.
  ‑ Step-1 :  count deaths in each age group (AGERECODE27)
  ‑ Step-2 :  for each age group report the counts and the difference
  ‑ Step-3 :  also add the overall (across-age-group) averages and
              their difference so it is clear “how much higher”
 --------------------------------------------------------------------*/
WITH age_counts AS (
    SELECT
        age."Description"                                          AS age_group,
        /* deaths whose description contains ‘discharge’
           minus the three excluded phrases                        */
        SUM(
            CASE
                WHEN icd."Description" ILIKE '%discharge%'
                     AND NOT (
                            icd."Description" ILIKE 'Urethral discharge%'
                         OR icd."Description" ILIKE '%Discharge of firework%'
                         OR icd."Description" ILIKE '%Legal intervention involving firearm discharge%'
                     )
                THEN 1 ELSE 0
            END
        )                                                          AS discharge_deaths,
        /* deaths whose description contains ‘vehicle’              */
        SUM(
            CASE
                WHEN icd."Description" ILIKE '%vehicle%'
                THEN 1 ELSE 0
            END
        )                                                          AS vehicle_deaths
    FROM  DEATH.DEATH.DEATHRECORDS    dr
    JOIN  DEATH.DEATH.ICD10CODE       icd  ON icd."Code" = dr."Icd10Code"
    JOIN  DEATH.DEATH.AGERECODE27     age  ON age."Code" = dr."AgeRecode27"
    WHERE dr."RaceRecode3" = 1          -- White
    GROUP BY age."Description"
)
SELECT
    age_group,
    discharge_deaths,
    vehicle_deaths,
    discharge_deaths - vehicle_deaths                               AS difference,
    /* overall averages (same value repeated on every row)          */
    AVG(discharge_deaths) OVER ()                                   AS avg_discharge_across_age_groups,
    AVG(vehicle_deaths)   OVER ()                                   AS avg_vehicle_across_age_groups,
    AVG(discharge_deaths) OVER () - AVG(vehicle_deaths) OVER ()     AS avg_difference_across_age_groups
FROM   age_counts
ORDER BY difference DESC NULLS LAST;