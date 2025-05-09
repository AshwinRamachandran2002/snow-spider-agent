WITH bank_branch_counts AS (
  SELECT
    REGEXP_EXTRACT(zip_code, r'^(\d{5})') AS zip_code,
    COUNT(*) AS num_branches
  FROM
    `bigquery-public-data.fdic_banks.locations`
  WHERE
    state = 'UT' AND zip_code IS NOT NULL AND zip_code != ''
  GROUP BY
    zip_code
  HAVING
    zip_code IS NOT NULL
),
min_branch_zip AS (
  SELECT
    zip_code
  FROM
    bank_branch_counts
  ORDER BY
    num_branches ASC,
    zip_code ASC
  LIMIT 1
)
SELECT
  c.geo_id AS Zip_Code,
  ROUND((c.employed_pop / c.pop_16_over) * 100, 4) AS Employment_Rate
FROM
  `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr` AS c
JOIN
  min_branch_zip AS mbz
ON
  c.geo_id = mbz.zip_code
WHERE
  c.pop_16_over > 0;