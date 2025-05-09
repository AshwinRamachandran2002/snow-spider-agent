WITH driver_points AS (
    SELECT r."year",
           res.driver_id,
           SUM(res.points) AS driver_pts
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r."year", res.driver_id
),
max_driver AS (
    SELECT "year",
           MAX(driver_pts) AS max_driver_pts
    FROM driver_points
    GROUP BY "year"
),
constructor_points AS (
    SELECT r."year",
           res.constructor_id,
           SUM(res.points) AS constructor_pts
    FROM results AS res
    JOIN races   AS r ON r.race_id = res.race_id
    GROUP BY r."year", res.constructor_id
),
max_constructor AS (
    SELECT "year",
           MAX(constructor_pts) AS max_constructor_pts
    FROM constructor_points
    GROUP BY "year"
),
year_totals AS (
    SELECT md."year",
           md.max_driver_pts + mc.max_constructor_pts AS total_pts
    FROM max_driver      AS md
    JOIN max_constructor AS mc ON md."year" = mc."year"
)
SELECT "year"
FROM year_totals
ORDER BY total_pts ASC, "year" ASC
LIMIT 3;