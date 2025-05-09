WITH yr2000 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2000
  FROM
    `bigquery-public-data.bls_qcew.2000_q*`
  WHERE
    SUBSTR(area_fips,1,2) = '49'   -- Utah counties
    AND area_fips <> '49000'       -- exclude state-level total
  GROUP BY area_fips
),
yr2018 AS (
  SELECT
    area_fips,
    AVG(month3_emplvl_23_construction) AS avg_2018
  FROM
    `bigquery-public-data.bls_qcew.2018_q*`
  WHERE
    SUBSTR(area_fips,1,2) = '49'
    AND area_fips <> '49000'
  GROUP BY area_fips
)
SELECT
  c.county_name                     AS utah_county,
  ROUND(100 * (y18.avg_2018 - y00.avg_2000) / y00.avg_2000 , 2) AS pct_increase
FROM
  yr2018 y18
JOIN
  yr2000 y00 USING (area_fips)
JOIN
  `bigquery-public-data.geo_us_boundaries.counties` AS c
    ON c.geo_id = y18.area_fips
ORDER BY
  pct_increase DESC
LIMIT 1;