WITH branch_counts AS (
    SELECT
        b.zip_code,
        COUNT(*) AS branch_count
    FROM
        `bigquery-public-data.fdic_banks.locations` AS b
    WHERE
        b.state = 'CO'
    GROUP BY
        b.zip_code
),
blockgroup_counts AS (
    SELECT
        z.zip_code,
        COUNT(DISTINCT bg.geo_id) AS blockgroup_count
    FROM
        `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
    JOIN
        `bigquery-public-data.geo_census_blockgroups.blockgroups_08` AS bg
    ON
        ST_INTERSECTS(z.zip_code_geom, bg.blockgroup_geom)
    WHERE
        z.state_code = 'CO'
    GROUP BY
        z.zip_code
)
SELECT
    bc.zip_code AS Zip_Code,
    ROUND(bc.branch_count / bgc.blockgroup_count, 4) AS Concentration
FROM
    branch_counts AS bc
JOIN
    blockgroup_counts AS bgc
ON
    bc.zip_code = bgc.zip_code
ORDER BY
    Concentration DESC
LIMIT 1