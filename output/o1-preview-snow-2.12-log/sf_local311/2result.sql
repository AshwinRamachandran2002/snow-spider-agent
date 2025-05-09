SELECT co."name" AS "Constructor", sub."year" AS "Year", 
       ROUND((sub."total_driver_points" + sub2."total_constructor_points"), 4) AS "Combined_Points"
FROM (
  -- Best driver per constructor per year
  SELECT res."constructor_id", ra."year", res."driver_id", 
         SUM(res."points") AS "total_driver_points",
         RANK() OVER (PARTITION BY res."constructor_id", ra."year" 
                      ORDER BY SUM(res."points") DESC) AS "driver_rank"
  FROM F1.F1.RESULTS res
  JOIN F1.F1.RACES ra ON res."race_id" = ra."race_id"
  GROUP BY res."constructor_id", ra."year", res."driver_id"
) sub
JOIN (
  -- Constructor total points per year
  SELECT res."constructor_id", ra."year", 
         SUM(res."points") AS "total_constructor_points"
  FROM F1.F1.RESULTS res
  JOIN F1.F1.RACES ra ON res."race_id" = ra."race_id"
  GROUP BY res."constructor_id", ra."year"
) sub2 ON sub."constructor_id" = sub2."constructor_id" 
       AND sub."year" = sub2."year"
JOIN F1.F1.CONSTRUCTORS co ON sub."constructor_id" = co."constructor_id"
WHERE sub."driver_rank" = 1
ORDER BY "Combined_Points" DESC NULLS LAST
LIMIT 3;