WITH driver_season AS (
    /* all driver‑seasons in the 1950s with at least two different rounds */
    SELECT
        r.driver_id,
        ra.year,
        MIN(ra.round)  AS first_round,
        MAX(ra.round)  AS last_round,
        COUNT(DISTINCT ra.round) AS race_rounds
    FROM results r
    JOIN races  ra ON ra.race_id = r.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
    GROUP BY r.driver_id, ra.year
    HAVING race_rounds >= 2
),
first_constructors AS (
    /* constructor in the driver’s first race of the season */
    SELECT
        ds.driver_id,
        ds.year,
        MIN(r.constructor_id) AS first_constructor   -- MIN to cope with rare multi‑entry races
    FROM driver_season ds
    JOIN results  r  ON r.driver_id = ds.driver_id
    JOIN races    ra ON ra.race_id  = r.race_id
    WHERE ra.year = ds.year
      AND ra.round = ds.first_round
    GROUP BY ds.driver_id, ds.year
),
last_constructors AS (
    /* constructor in the driver’s last race of the season */
    SELECT
        ds.driver_id,
        ds.year,
        MIN(r.constructor_id) AS last_constructor
    FROM driver_season ds
    JOIN results  r  ON r.driver_id = ds.driver_id
    JOIN races    ra ON ra.race_id  = r.race_id
    WHERE ra.year = ds.year
      AND ra.round = ds.last_round
    GROUP BY ds.driver_id, ds.year
),
qualified AS (
    /* keep seasons where the first and last constructors match */
    SELECT
        ds.driver_id,
        ds.year
    FROM driver_season      ds
    JOIN first_constructors fc USING (driver_id, year)
    JOIN last_constructors  lc USING (driver_id, year)
    WHERE fc.first_constructor = lc.last_constructor
)
SELECT DISTINCT d.full_name
FROM qualified       q
JOIN drivers_ext d ON d.driver_id = q.driver_id
ORDER BY d.full_name;