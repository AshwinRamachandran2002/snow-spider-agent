WITH driver_year_totals AS (
    SELECT ra."year",
           r."driver_id",
           SUM(r."points") AS driver_pts
    FROM   "results" r
    JOIN   "races"   ra USING ("race_id")
    GROUP  BY ra."year", r."driver_id"
),
max_driver_per_year AS (
    SELECT "year",
           MAX(driver_pts) AS max_driver_pts
    FROM   driver_year_totals
    GROUP  BY "year"
),
constructor_year_totals AS (
    SELECT ra."year",
           r."constructor_id",
           SUM(r."points") AS constructor_pts
    FROM   "results" r
    JOIN   "races"   ra USING ("race_id")
    GROUP  BY ra."year", r."constructor_id"
),
max_constructor_per_year AS (
    SELECT "year",
           MAX(constructor_pts) AS max_constructor_pts
    FROM   constructor_year_totals
    GROUP  BY "year"
)
SELECT md."year"
FROM   max_driver_per_year      md
JOIN   max_constructor_per_year mc USING ("year")
ORDER  BY (md.max_driver_pts + mc.max_constructor_pts) ASC
LIMIT 3;