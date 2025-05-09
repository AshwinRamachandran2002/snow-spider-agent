WITH bank_counts_per_zip AS (
    SELECT
        l.zip_code,
        COUNT(*) AS bank_count
    FROM
        `bigquery-public-data.fdic_banks.locations` l
    WHERE
        l.state = 'CO'
    GROUP BY
        l.zip_code
),
blockgroup_zip_overlap AS (
    SELECT
        b.geo_id,
        z.zip_code,
        ST_AREA(ST_INTERSECTION(b.blockgroup_geom, z.zip_code_geom)) / ST_AREA(b.blockgroup_geom) AS overlap_ratio
    FROM
        `bigquery-public-data.geo_census_blockgroups.blockgroups_08` AS b
        JOIN `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
        ON ST_INTERSECTS(b.blockgroup_geom, z.zip_code_geom)
    WHERE
        z.state_code = 'CO'
),
adjusted_bank_counts AS (
    SELECT
        b.geo_id,
        b.zip_code,
        bc.bank_count,
        b.overlap_ratio,
        bc.bank_count * b.overlap_ratio AS adjusted_bank_count
    FROM
        blockgroup_zip_overlap b
        JOIN bank_counts_per_zip bc
        ON b.zip_code = bc.zip_code
)
SELECT
    zip_code,
    ROUND(SUM(adjusted_bank_count) / COUNT(DISTINCT geo_id), 4) AS bank_concentration
FROM
    adjusted_bank_counts
GROUP BY
    zip_code
ORDER BY
    bank_concentration DESC
LIMIT 1;