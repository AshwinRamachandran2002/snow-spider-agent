SELECT c."name" AS "Constructor_Name", bd."year" AS "Year", ROUND(bd."driver_total_points" + cp."constructor_points", 4) AS "Combined_Points"
FROM (
  SELECT t."constructor_id", t."year", t."driver_total_points"
  FROM (
    SELECT results."constructor_id", r."year", results."driver_id", SUM(results."points") AS "driver_total_points",
      ROW_NUMBER() OVER (PARTITION BY results."constructor_id", r."year" ORDER BY SUM(results."points") DESC) AS "rank"
    FROM "results" results
    JOIN "races" r ON results."race_id" = r."race_id"
    GROUP BY results."constructor_id", r."year", results."driver_id"
  ) t
  WHERE t."rank" = 1
) bd
JOIN (
   SELECT cs."constructor_id", r."year", SUM(cs."points") AS "constructor_points"
   FROM "constructor_standings" cs
   JOIN "races" r ON cs."race_id" = r."race_id"
   GROUP BY cs."constructor_id", r."year"
) cp ON bd."constructor_id" = cp."constructor_id" AND bd."year" = cp."year"
JOIN "constructors" c ON bd."constructor_id" = c."constructor_id"
ORDER BY "Combined_Points" DESC
LIMIT 3;