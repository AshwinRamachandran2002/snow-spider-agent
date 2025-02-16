-- Task: Calculate the percentage growth rates (to two decimal places) of average annual wages for all industries in Allegheny County (part of the Pittsburgh area) and the Consumer Price Index (CPI) for all items in the Pittsburgh area between 1998 and 2017. Determine whether the average annual wages kept pace with inflation over that period.

WITH geo AS (
  SELECT DISTINCT geo_id
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE county_name = "Allegheny" 
),
avg_wage_1998 AS(
  SELECT
    ROUND(AVG(avg_wkly_wage_10_total_all_industries) * 52, 2) AS wages_1998
  FROM
    `bigquery-public-data.bls_qcew.1998*`
  WHERE
    geoid = (SELECT geo_id FROM geo) -- Selecting Allegheny County
),
avg_wage_2017 AS (
  SELECT
    ROUND(AVG(avg_wkly_wage_10_total_all_industries) * 52, 2) AS wages_2017
  FROM
    `bigquery-public-data.bls_qcew.2017*`
  WHERE
    geoid = (SELECT geo_id FROM geo) -- Selecting Allegheny County
),
avg_cpi_1998 AS (
  SELECT
    AVG(value) AS cpi_1998
  FROM
    `bigquery-public-data.bls.cpi_u` c
  WHERE
    year = 1998
    AND item_code IN (
      SELECT DISTINCT item_code FROM `bigquery-public-data.bls.cpi_u` WHERE LOWER(item_name) = "all items"
    )
    AND area_code = (
      SELECT DISTINCT area_code FROM `bigquery-public-data.bls.cpi_u` WHERE area_name LIKE '%Pittsburgh%'
    )
), 
avg_cpi_2017 AS (
  SELECT
    AVG(value) AS cpi_2017
  FROM
    `bigquery-public-data.bls.cpi_u` c
  WHERE
    year = 2017
    AND item_code IN (
      SELECT DISTINCT item_code FROM `bigquery-public-data.bls.cpi_u` WHERE LOWER(item_name) = "all items"
    )
    AND area_code = (
      SELECT DISTINCT area_code FROM `bigquery-public-data.bls.cpi_u` WHERE area_name LIKE '%Pittsburgh%'
    )
)
SELECT
  ROUND((wages_2017 - wages_1998) / wages_1998 * 100, 2) AS wages_percent_change,
  ROUND((cpi_2017 - cpi_1998) / cpi_1998 * 100, 2) AS cpi_percent_change
FROM
  avg_wage_2017,
  avg_wage_1998,
  avg_cpi_2017,
  avg_cpi_1998