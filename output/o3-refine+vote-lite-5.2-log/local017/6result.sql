WITH collisions_with_year AS (
    SELECT
        CAST(substr("collision_date", 1, 4) AS INTEGER) AS year,
        "primary_collision_factor"                     AS factor
    FROM "collisions"
    WHERE "collision_date" IS NOT NULL
      AND "primary_collision_factor" IS NOT NULL
),
factor_counts AS (                    -- how often each factor appears in a year
    SELECT
        year,
        factor,
        COUNT(*) AS cnt
    FROM collisions_with_year
    GROUP BY year, factor
),
ranked AS (                            -- rank factors by frequency within each year
    SELECT
        year,
        factor,
        cnt,
        ROW_NUMBER() OVER (PARTITION BY year ORDER BY cnt DESC, factor) AS rn
    FROM factor_counts
),
top_two AS (                           -- keep only the two most common factors per year
    SELECT
        year,
        factor
    FROM ranked
    WHERE rn <= 2
),
pair_per_year AS (                     -- canonical (alphabetical) pair string for each year
    SELECT
        year,
        GROUP_CONCAT(factor, '|') AS pair
    FROM (
        SELECT year, factor
        FROM top_two
        ORDER BY year, factor          -- alphabetical so ordering is consistent
    )
    GROUP BY year
    HAVING COUNT(*) = 2                -- ensure the year actually has two factors
),
pair_freq AS (                         -- how many years share the same pair
    SELECT
        pair,
        COUNT(*) AS yrs
    FROM pair_per_year
    GROUP BY pair
),
max_pair_freq AS (                     -- frequency of the most common pair
    SELECT MAX(yrs) AS max_yrs FROM pair_freq
)
SELECT
    p.year
FROM pair_per_year AS p
JOIN pair_freq      AS f ON p.pair = f.pair
JOIN max_pair_freq  AS m                -- years whose pair is NOT the most common one
WHERE f.yrs < m.max_yrs;