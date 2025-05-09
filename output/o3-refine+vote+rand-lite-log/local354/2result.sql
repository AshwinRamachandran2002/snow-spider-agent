WITH driver_race_data AS (
    -- all race participations in the 1950‑1959 seasons
    SELECT
        res.driver_id,
        res.constructor_id,
        ra.year,
        ra.round
    FROM results            AS res
    JOIN races              AS ra ON ra.race_id = res.race_id
    WHERE ra.year BETWEEN 1950 AND 1959
),
participation AS (
    -- how many races each driver entered in every season,
    -- plus the first and last rounds they started
    SELECT
        driver_id,
        year,
        COUNT(DISTINCT round)        AS races_entered,
        MIN(round)                   AS first_round,
        MAX(round)                   AS last_round
    FROM driver_race_data
    GROUP BY driver_id, year
    HAVING races_entered >= 2        -- at least two distinct rounds
),
first_constructor AS (
    -- constructor used in the first race of the season
    SELECT
        p.driver_id,
        p.year,
        d.constructor_id
    FROM participation      AS p
    JOIN driver_race_data   AS d
         ON  d.driver_id = p.driver_id
         AND d.year      = p.year
         AND d.round     = p.first_round
),
last_constructor AS (
    -- constructor used in the last race of the season
    SELECT
        p.driver_id,
        p.year,
        d.constructor_id
    FROM participation      AS p
    JOIN driver_race_data   AS d
         ON  d.driver_id = p.driver_id
         AND d.year      = p.year
         AND d.round     = p.last_round
),
qualified_seasons AS (
    -- seasons where first and last constructor are identical
    SELECT
        f.driver_id,
        f.year,
        f.constructor_id
    FROM first_constructor  AS f
    JOIN last_constructor   AS l
         ON  l.driver_id     = f.driver_id
         AND l.year          = f.year
         AND l.constructor_id = f.constructor_id
)
SELECT DISTINCT
       qs.year                              AS season,
       drv.forename || ' ' || drv.surname   AS driver_name,
       cons.name                            AS constructor_name
FROM qualified_seasons  AS qs
JOIN drivers             AS drv  ON drv.driver_id      = qs.driver_id
JOIN constructors        AS cons ON cons.constructor_id = qs.constructor_id
ORDER BY qs.year, driver_name;