WITH driver_totals AS (
    -- points per driver per season
    SELECT ra.year,
           re.driver_id,
           SUM(re.points) AS driver_points
    FROM results  AS re
    JOIN races    AS ra USING (race_id)
    GROUP BY ra.year, re.driver_id
),
max_driver AS (
    -- highest driver-points total each season
    SELECT year,
           MAX(driver_points) AS max_driver_points
    FROM driver_totals
    GROUP BY year
),
constructor_totals AS (
    -- points per constructor per season
    SELECT ra.year,
           re.constructor_id,
           SUM(re.points) AS constructor_points
    FROM results AS re
    JOIN races   AS ra USING (race_id)
    GROUP BY ra.year, re.constructor_id
),
max_constructor AS (
    -- highest constructor-points total each season
    SELECT year,
           MAX(constructor_points) AS max_constructor_points
    FROM constructor_totals
    GROUP BY year
)
SELECT md.year
FROM max_driver      AS md
JOIN max_constructor AS mc
  ON md.year = mc.year
ORDER BY (md.max_driver_points + mc.max_constructor_points) ASC,
         md.year ASC
LIMIT 3;