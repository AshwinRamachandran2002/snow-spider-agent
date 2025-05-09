WITH
    driver_totals AS (
        SELECT ra.year,
               r.driver_id,
               SUM(r.points) AS pts
        FROM   results r
        JOIN   races   ra ON ra.race_id = r.race_id
        GROUP  BY ra.year, r.driver_id
    ),
    driver_max AS (
        SELECT year,
               MAX(pts) AS max_driver_pts
        FROM   driver_totals
        GROUP  BY year
    ),
    constructor_totals AS (
        SELECT ra.year,
               r.constructor_id,
               SUM(r.points) AS pts
        FROM   results r
        JOIN   races   ra ON ra.race_id = r.race_id
        GROUP  BY ra.year, r.constructor_id
    ),
    constructor_max AS (
        SELECT year,
               MAX(pts) AS max_constructor_pts
        FROM   constructor_totals
        GROUP  BY year
    ),
    year_totals AS (
        SELECT dm.year,
               dm.max_driver_pts + cm.max_constructor_pts AS total_points
        FROM   driver_max      dm
        JOIN   constructor_max cm ON cm.year = dm.year
    )
SELECT year,
       ROUND(total_points, 4) AS total_points
FROM   year_totals
ORDER  BY total_points ASC,
          year ASC
LIMIT  3;