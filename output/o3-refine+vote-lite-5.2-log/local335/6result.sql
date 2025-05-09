WITH driver_points AS (
    SELECT
        ra.year,
        re.driver_id,
        re.constructor_id,
        SUM(re.points) AS total_points
    FROM results re
    JOIN races ra ON ra.race_id = re.race_id
    WHERE ra.year >= 2001
    GROUP BY
        ra.year,
        re.driver_id,
        re.constructor_id
),
-- which constructor did each driver score most of his points with that year?
driver_primary_team AS (
    SELECT
        dp.year,
        dp.driver_id,
        dp.constructor_id
    FROM driver_points dp
    JOIN (
        SELECT
            year,
            driver_id,
            MAX(total_points) AS max_pts
        FROM driver_points
        GROUP BY year, driver_id
    ) mx
      ON mx.year = dp.year
     AND mx.driver_id = dp.driver_id
     AND mx.max_pts = dp.total_points
),
-- aggregate points per driver for the season (ignore drivers with 0)
driver_season_totals AS (
    SELECT
        year,
        driver_id,
        SUM(total_points) AS season_pts
    FROM driver_points
    GROUP BY year, driver_id
    HAVING season_pts > 0
),
-- minimum points scored (among point‑scorers) in each season
min_points_per_season AS (
    SELECT
        year,
        MIN(season_pts) AS min_pts
    FROM driver_season_totals
    GROUP BY year
),
-- drivers who had that minimum
lowest_scoring_drivers AS (
    SELECT
        dst.year,
        dst.driver_id
    FROM driver_season_totals dst
    JOIN min_points_per_season mps
      ON mps.year = dst.year
     AND mps.min_pts = dst.season_pts
),
-- map those drivers to their primary constructor that season
lowest_driver_teams AS (
    SELECT
        lsd.year,
        dpt.constructor_id
    FROM lowest_scoring_drivers lsd
    JOIN driver_primary_team dpt
      ON dpt.year = lsd.year
     AND dpt.driver_id = lsd.driver_id
)
SELECT
    co.name AS constructor,
    COUNT(DISTINCT ldt.year) AS seasons_with_lowest_point_driver
FROM lowest_driver_teams ldt
JOIN constructors co ON co.constructor_id = ldt.constructor_id
GROUP BY co.constructor_id, co.name
ORDER BY seasons_with_lowest_point_driver DESC,
         co.name
LIMIT 5;