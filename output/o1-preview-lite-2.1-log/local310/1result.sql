WITH last_races AS (
  SELECT "year", MAX("race_id") as "last_race_id"
  FROM "races"
  GROUP BY "year"
),
driver_max_points AS (
  SELECT lr."year", MAX(ds."points") AS "max_driver_points"
  FROM "driver_standings" ds
  JOIN last_races lr ON ds."race_id" = lr."last_race_id"
  GROUP BY lr."year"
),
constructor_max_points AS (
  SELECT lr."year", MAX(cs."points") AS "max_constructor_points"
  FROM "constructor_standings" cs
  JOIN last_races lr ON cs."race_id" = lr."last_race_id"
  GROUP BY lr."year"
)
SELECT dmp."year" AS "Year",
       ROUND(dmp."max_driver_points" + cmp."max_constructor_points", 4) AS "Sum_of_Highest_Points"
FROM driver_max_points dmp
JOIN constructor_max_points cmp ON dmp."year" = cmp."year"
ORDER BY "Sum_of_Highest_Points" ASC
LIMIT 3;