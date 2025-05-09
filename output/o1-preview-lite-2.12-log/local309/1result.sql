WITH
driver_totals AS (
  SELECT r."year", res."driver_id", SUM(res."points") AS "total_points"
  FROM "results" res
  JOIN "races" r ON res."race_id" = r."race_id"
  GROUP BY r."year", res."driver_id"
),
max_driver_points AS (
  SELECT "year", MAX("total_points") AS "max_points"
  FROM driver_totals
  GROUP BY "year"
),
top_drivers AS (
  SELECT dt."year", dt."driver_id"
  FROM driver_totals dt
  JOIN max_driver_points mdp ON dt."year" = mdp."year" AND ROUND(dt."total_points", 4) = ROUND(mdp."max_points", 4)
),
constructor_totals AS (
  SELECT r."year", res."constructor_id", SUM(res."points") AS "total_points"
  FROM "results" res
  JOIN "races" r ON res."race_id" = r."race_id"
  GROUP BY r."year", res."constructor_id"
),
max_constructor_points AS (
  SELECT "year", MAX("total_points") AS "max_points"
  FROM constructor_totals
  GROUP BY "year"
),
top_constructors AS (
  SELECT ct."year", ct."constructor_id"
  FROM constructor_totals ct
  JOIN max_constructor_points mcp ON ct."year" = mcp."year" AND ROUND(ct."total_points", 4) = ROUND(mcp."max_points", 4)
),
driver_names AS (
  SELECT td."year", d."full_name" AS "Driver_Name"
  FROM top_drivers td
  JOIN "drivers" d ON td."driver_id" = d."driver_id"
),
constructor_names AS (
  SELECT tc."year", c."name" AS "Constructor_Name"
  FROM top_constructors tc
  JOIN "constructors" c ON tc."constructor_id" = c."constructor_id"
),
combined AS (
  SELECT dn."year", dn."Driver_Name", cn."Constructor_Name"
  FROM driver_names dn
  JOIN constructor_names cn ON dn."year" = cn."year"
)
SELECT "year", "Driver_Name", "Constructor_Name"
FROM combined
ORDER BY "year"