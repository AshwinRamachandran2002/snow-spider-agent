WITH
-- limit drives to seasons in the 1950s
d50 AS (
    SELECT year,
           driver_id,
           constructor_id,
           first_round,
           last_round
    FROM drives
    WHERE year BETWEEN 1950 AND 1959
),

-- for every driver‑season, identify the very first round they started
first_stint AS (
    SELECT year,
           driver_id,
           constructor_id AS first_constructor_id,
           MIN(first_round) AS first_round
    FROM d50
    GROUP BY year, driver_id
),

-- for every driver‑season, identify the very last round they raced
last_stint AS (
    SELECT year,
           driver_id,
           constructor_id AS last_constructor_id,
           MAX(last_round) AS last_round
    FROM d50
    GROUP BY year, driver_id
),

-- season(s) where the constructor of the first and last race is identical
eligible_seasons AS (
    SELECT f.year,
           f.driver_id,
           f.first_round,
           l.last_round
    FROM first_stint f
    JOIN last_stint  l
          ON  l.year       = f.year
          AND l.driver_id  = f.driver_id
    WHERE f.first_constructor_id = l.last_constructor_id      -- same team at start & end
      AND l.last_round - f.first_round >= 1                   -- at least two different rounds
)

SELECT DISTINCT
       dr.driver_id,
       dr.forename || ' ' || dr.surname AS driver_name
FROM eligible_seasons  es
JOIN drivers           dr ON dr.driver_id = es.driver_id
ORDER BY dr.driver_id;