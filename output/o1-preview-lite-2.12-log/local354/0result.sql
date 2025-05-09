WITH driver_seasons AS (
    SELECT
        drivers.driver_id,
        drivers.full_name,
        races.year,
        COUNT(DISTINCT races.round) AS total_rounds,
        MIN(races.round) AS first_round,
        MAX(races.round) AS last_round
    FROM drivers
    JOIN results ON drivers.driver_id = results.driver_id
    JOIN races ON results.race_id = races.race_id
    WHERE races.year BETWEEN 1950 AND 1959
    GROUP BY drivers.driver_id, races.year
    HAVING COUNT(DISTINCT races.round) >= 2
),
first_constructors AS (
    SELECT
      ds.driver_id,
      ds.year,
      res.constructor_id AS first_constructor_id
    FROM driver_seasons ds
    JOIN results res ON ds.driver_id = res.driver_id
    JOIN races r ON res.race_id = r.race_id
    WHERE r.year = ds.year AND r.round = ds.first_round
),
last_constructors AS (
    SELECT
      ds.driver_id,
      ds.year,
      res.constructor_id AS last_constructor_id
    FROM driver_seasons ds
    JOIN results res ON ds.driver_id = res.driver_id
    JOIN races r ON res.race_id = r.race_id
    WHERE r.year = ds.year AND r.round = ds.last_round
),
driver_constructors AS (
    SELECT
        ds.driver_id,
        ds.full_name,
        ds.year,
        fc.first_constructor_id,
        lc.last_constructor_id
    FROM driver_seasons ds
    JOIN first_constructors fc ON ds.driver_id = fc.driver_id AND ds.year = fc.year
    JOIN last_constructors lc ON ds.driver_id = lc.driver_id AND ds.year = lc.year
)
SELECT
    dc.driver_id,
    dc.full_name AS driver_name,
    dc.year,
    dc.first_constructor_id AS constructor_id,
    constructors.name AS constructor_name
FROM driver_constructors dc
JOIN constructors ON constructors.constructor_id = dc.first_constructor_id
WHERE dc.first_constructor_id = dc.last_constructor_id;