WITH
-- Trees from 1995 that were alive, with species, rounded location, and fall color
trees_1995_alive AS (
    SELECT
        ROUND(latitude, 4) AS lat_round,
        ROUND(longitude, 4) AS lon_round,
        LOWER(TRIM(spc_latin)) AS species_name,
        ts.fall_color
    FROM
        `bigquery-public-data.new_york.tree_census_1995` AS t1995
    JOIN
        `bigquery-public-data.new_york.tree_species` AS ts
    ON
        LOWER(TRIM(t1995.spc_latin)) = LOWER(TRIM(ts.species_scientific_name))
    WHERE
        LOWER(t1995.status) NOT IN ('dead', 'stump')
        AND t1995.spc_latin IS NOT NULL
        AND t1995.latitude IS NOT NULL
        AND t1995.longitude IS NOT NULL
),

-- Trees from 2015 that are alive, with species, rounded location
trees_2015_alive AS (
    SELECT
        ROUND(latitude, 4) AS lat_round,
        ROUND(longitude, 4) AS lon_round,
        LOWER(TRIM(spc_latin)) AS species_name
    FROM
        `bigquery-public-data.new_york.tree_census_2015` AS t2015
    WHERE
        LOWER(t2015.status) = 'alive'
        AND t2015.spc_latin IS NOT NULL
        AND t2015.latitude IS NOT NULL
        AND t2015.longitude IS NOT NULL
),

-- Trees that were alive in 1995 and are still alive in 2015, with fall color
trees_still_alive AS (
    SELECT DISTINCT
        t1995.species_name,
        t1995.fall_color,
        t1995.lat_round,
        t1995.lon_round
    FROM
        trees_1995_alive AS t1995
    INNER JOIN
        trees_2015_alive AS t2015
    ON
        t1995.species_name = t2015.species_name
        AND t1995.lat_round = t2015.lat_round
        AND t1995.lon_round = t2015.lon_round
),

-- Counts of alive trees in 1995 per fall color
alive_1995_counts AS (
    SELECT
        fall_color,
        COUNT(*) AS Trees_in_1995
    FROM
        trees_1995_alive
    GROUP BY
        fall_color
),

-- Counts of trees still alive in 2015 per fall color
alive_both_years_counts AS (
    SELECT
        fall_color,
        COUNT(*) AS Trees_in_2015
    FROM
        trees_still_alive
    GROUP BY
        fall_color
)

SELECT
    alive_1995_counts.fall_color AS Fall_Color,
    alive_1995_counts.Trees_in_1995,
    IFNULL(alive_both_years_counts.Trees_in_2015, 0) AS Trees_in_2015
FROM
    alive_1995_counts
LEFT JOIN
    alive_both_years_counts
ON
    alive_1995_counts.fall_color = alive_both_years_counts.fall_color
ORDER BY
    Fall_Color;