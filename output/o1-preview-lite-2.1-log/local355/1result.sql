WITH total_races_per_year AS (
  SELECT "year", COUNT(*) AS "total_races"
  FROM "races"
  GROUP BY "year"
),
driver_races_per_year AS (
  SELECT re."driver_id", r."year", COUNT(*) AS "races_participated"
  FROM "results" re
  JOIN "races" r ON re."race_id" = r."race_id"
  GROUP BY re."driver_id", r."year"
),
drivers_missed_few_races AS (
  SELECT drp."driver_id", drp."year", drp."races_participated", trpy."total_races"
  FROM driver_races_per_year drp
  JOIN total_races_per_year trpy ON drp."year" = trpy."year"
  WHERE (trpy."total_races" - drp."races_participated") < 3
    AND (trpy."total_races" - drp."races_participated") > 0
),
missed_races AS (
  SELECT dmf."driver_id", dmf."year", r."round"
  FROM drivers_missed_few_races dmf
  JOIN "races" r ON r."year" = dmf."year"
  LEFT JOIN "results" re ON re."race_id" = r."race_id" AND re."driver_id" = dmf."driver_id"
  WHERE re."driver_id" IS NULL
),
first_last_missed_round AS (
  SELECT m."driver_id", m."year", MIN(m."round") AS "first_missed_round", MAX(m."round") AS "last_missed_round"
  FROM missed_races m
  GROUP BY m."driver_id", m."year"
),
constructors_before_after AS (
  SELECT flmr."driver_id", flmr."year",

  -- Constructor before missed races
  (SELECT re_before."constructor_id"
   FROM "results" re_before
   JOIN "races" r_before ON re_before."race_id" = r_before."race_id"
   WHERE re_before."driver_id" = flmr."driver_id" AND r_before."year" = flmr."year"
     AND r_before."round" < flmr."first_missed_round"
   ORDER BY r_before."round" DESC
   LIMIT 1) AS "constructor_before_miss",

  -- Constructor after missed races
  (SELECT re_after."constructor_id"
   FROM "results" re_after
   JOIN "races" r_after ON re_after."race_id" = r_after."race_id"
   WHERE re_after."driver_id" = flmr."driver_id" AND r_after."year" = flmr."year"
     AND r_after."round" > flmr."last_missed_round"
   ORDER BY r_after."round" ASC
   LIMIT 1) AS "constructor_after_miss",

  flmr."first_missed_round", flmr."last_missed_round"
  FROM first_last_missed_round flmr
),
drivers_switched_teams_during_miss AS (
  SELECT cba.*
  FROM constructors_before_after cba
  WHERE cba."constructor_before_miss" IS NOT NULL
    AND cba."constructor_after_miss" IS NOT NULL
    AND cba."constructor_before_miss" != cba."constructor_after_miss"
)
SELECT
  cba."year",
  ROUND(AVG(cba."first_missed_round"), 4) AS "Average_First_Missed_Round",
  ROUND(AVG(cba."last_missed_round"), 4) AS "Average_Last_Missed_Round"
FROM drivers_switched_teams_during_miss cba
GROUP BY cba."year"
ORDER BY cba."year";