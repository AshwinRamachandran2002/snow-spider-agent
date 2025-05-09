-- top 10 tree species (Latin name in upper‑case) with counts and growth between 1995‑2015
WITH census AS (
    -- union the three tree‑census vintages
    SELECT 1995 AS census_year,
           UPPER(TRIM(spc_latin))        AS latin,
           spc_common,
           LOWER(COALESCE(status,''))    AS status_lower
    FROM `bigquery-public-data.new_york.tree_census_1995`
    UNION ALL
    SELECT 2005,
           UPPER(TRIM(spc_latin)),
           spc_common,
           LOWER(COALESCE(status,'')) 
    FROM `bigquery-public-data.new_york.tree_census_2005`
    UNION ALL
    SELECT 2015,
           UPPER(TRIM(spc_latin)),
           spc_common,
           LOWER(COALESCE(status,'')) 
    FROM `bigquery-public-data.new_york.tree_census_2015`
),
filtered AS (
    -- keep only rows that have a non‑empty Latin name
    SELECT
        census_year,
        latin,
        spc_common,
        CASE WHEN status_lower LIKE 'dead%' THEN 1 ELSE 0 END AS is_dead
    FROM census
    WHERE latin IS NOT NULL AND latin <> ''
),
by_year AS (
    -- yearly totals per species
    SELECT
        latin,
        ANY_VALUE(spc_common)                             AS common_name,
        census_year,
        COUNT(1)                                          AS total,
        SUM(CASE WHEN is_dead = 0 THEN 1 ELSE 0 END)      AS alive,
        SUM(CASE WHEN is_dead = 1 THEN 1 ELSE 0 END)      AS dead
    FROM filtered
    GROUP BY latin, census_year
),
pivoted AS (
    -- pivot each metric into separate year columns
    SELECT
        latin,
        common_name,
        SUM(CASE WHEN census_year = 1995 THEN total  ELSE 0 END) AS total_1995,
        SUM(CASE WHEN census_year = 2005 THEN total  ELSE 0 END) AS total_2005,
        SUM(CASE WHEN census_year = 2015 THEN total  ELSE 0 END) AS total_2015,

        SUM(CASE WHEN census_year = 1995 THEN alive  ELSE 0 END) AS alive_1995,
        SUM(CASE WHEN census_year = 2005 THEN alive  ELSE 0 END) AS alive_2005,
        SUM(CASE WHEN census_year = 2015 THEN alive  ELSE 0 END) AS alive_2015,

        SUM(CASE WHEN census_year = 1995 THEN dead   ELSE 0 END) AS dead_1995,
        SUM(CASE WHEN census_year = 2005 THEN dead   ELSE 0 END) AS dead_2005,
        SUM(CASE WHEN census_year = 2015 THEN dead   ELSE 0 END) AS dead_2015
    FROM by_year
    GROUP BY latin, common_name
),
final AS (
    -- compute growth between 1995 and 2015
    SELECT
        latin                      AS species_latin,
        common_name                AS species_common,
        total_1995,  alive_1995,  dead_1995,
        total_2005,  alive_2005,  dead_2005,
        total_2015,  alive_2015,  dead_2015,
        total_2015 - total_1995    AS growth_total_1995_2015,
        alive_2015 - alive_1995    AS growth_alive_1995_2015,
        dead_2015  - dead_1995     AS growth_dead_1995_2015
    FROM pivoted
)
SELECT *
FROM final
ORDER BY growth_total_1995_2015 DESC
LIMIT 10;