WITH total_races AS (
  SELECT "year", COUNT(*) AS "total_races"
  FROM "races"
  GROUP BY "year"
),
driver_race_counts AS (
  SELECT r."driver_id", ra."year", COUNT(*) AS "races_participated"
  FROM "results" r
  JOIN "races" ra ON r."race_id" = ra."race_id"
  GROUP BY r."driver_id", ra."year"
),
driver_missed_races AS (
  SELECT drc."driver_id", drc."year",
    tr."total_races",
    drc."races_participated",
    (tr."total_races" - drc."races_participated") AS "races_missed"
  FROM driver_race_counts drc
  JOIN total_races tr ON drc."year" = tr."year"
),
qualified_drivers AS (
  SELECT *
  FROM driver_missed_races
  WHERE "races_missed" IN (1, 2)
),
race_rounds AS (
  SELECT "year", "round"
  FROM "races"
),
driver_race_rounds AS (
  SELECT r."driver_id", ra."year", ra."round"
  FROM "results" r
  JOIN "races" ra ON r."race_id" = ra."race_id"
),
missed_rounds AS (
  SELECT qd."driver_id", qd."year", rr."round"
  FROM qualified_drivers qd
  JOIN race_rounds rr ON qd."year" = rr."year"
  LEFT JOIN driver_race_rounds drr ON qd."driver_id" = drr."driver_id"
    AND qd."year" = drr."year" AND rr."round" = drr."round"
  WHERE drr."driver_id" IS NULL
),
missed_rounds_grouped AS (
  SELECT "driver_id", "year",
    MIN("round") AS "first_missed_round",
    MAX("round") AS "last_missed_round"
  FROM missed_rounds
  GROUP BY "driver_id", "year"
),
pre_missed_constructor AS (
  SELECT r."driver_id", ra."year",
    MAX(ra."round") AS "round",
    r."constructor_id"
  FROM "results" r
  JOIN "races" ra ON r."race_id" = ra."race_id"
  JOIN missed_rounds_grouped mrg ON r."driver_id" = mrg."driver_id" AND ra."year" = mrg."year"
  WHERE ra."round" < mrg."first_missed_round"
  GROUP BY r."driver_id", ra."year"
),
post_missed_constructor AS (
  SELECT r."driver_id", ra."year",
    MIN(ra."round") AS "round",
    r."constructor_id"
  FROM "results" r
  JOIN "races" ra ON r."race_id" = ra."race_id"
  JOIN missed_rounds_grouped mrg ON r."driver_id" = mrg."driver_id" AND ra."year" = mrg."year"
  WHERE ra."round" > mrg."last_missed_round"
  GROUP BY r."driver_id", ra."year"
),
driver_transfers AS (
  SELECT pmc."driver_id", pmc."year",
    pmc."constructor_id" AS "pre_constructor_id",
    pmsc."constructor_id" AS "post_constructor_id",
    mrg."first_missed_round",
    mrg."last_missed_round"
  FROM pre_missed_constructor pmc
  JOIN post_missed_constructor pmsc ON pmc."driver_id" = pmsc."driver_id" AND pmc."year" = pmsc."year"
  JOIN missed_rounds_grouped mrg ON pmc."driver_id" = mrg."driver_id" AND pmc."year" = mrg."year"
  WHERE pmc."constructor_id" <> pmsc."constructor_id"
)
SELECT dt."year" AS "Year",
  ROUND(AVG(dt."first_missed_round"), 4) AS "Average_First_Missed_Round",
  ROUND(AVG(dt."last_missed_round"), 4) AS "Average_Last_Missed_Round"
FROM driver_transfers dt
GROUP BY dt."year"
ORDER BY dt."year";