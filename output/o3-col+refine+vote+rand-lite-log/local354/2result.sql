WITH race_results AS (
    SELECT r.driver_id,
           ra.year,
           ra.round,
           r.constructor_id
    FROM results AS r
    JOIN races   AS ra ON ra.race_id = r.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
driver_season_info AS (
    SELECT driver_id,
           year,
           MIN(round)                                 AS first_round,
           MAX(round)                                 AS last_round,
           COUNT(DISTINCT round)                      AS rounds_entered
    FROM race_results
    GROUP BY driver_id, year
    HAVING rounds_entered >= 2                       -- took part in at least two rounds
),
first_constructor AS (
    SELECT dsi.driver_id,
           dsi.year,
           rr.constructor_id                          AS first_constructor
    FROM driver_season_info AS dsi
    JOIN race_results      AS rr
      ON rr.driver_id = dsi.driver_id
     AND rr.year      = dsi.year
     AND rr.round     = dsi.first_round               -- constructor in first race
),
last_constructor AS (
    SELECT dsi.driver_id,
           dsi.year,
           rr.constructor_id                          AS last_constructor
    FROM driver_season_info AS dsi
    JOIN race_results      AS rr
      ON rr.driver_id = dsi.driver_id
     AND rr.year      = dsi.year
     AND rr.round     = dsi.last_round                -- constructor in last race
),
qualified_seasons AS (
    SELECT fc.driver_id, fc.year
    FROM first_constructor AS fc
    JOIN last_constructor  AS lc
      ON lc.driver_id = fc.driver_id
     AND lc.year      = fc.year
    WHERE fc.first_constructor = lc.last_constructor  -- same constructor at start & end
)
SELECT DISTINCT qs.driver_id,
       d.forename || ' ' || d.surname AS driver_name
FROM qualified_seasons AS qs
JOIN drivers           AS d  ON d.driver_id = qs.driver_id
ORDER BY driver_name;