-- Task: What was the average annual wage for all industries in Allegheny County in 1998?
WITH geo AS (
  SELECT DISTINCT geo_id
  FROM `bigquery-public-data.geo_us_boundaries.counties`
  WHERE county_name = "Allegheny"
)
SELECT
  ROUND(AVG(avg_wkly_wage_10_total_all_industries) * 52, 2) AS wages_1998
FROM
  `bigquery-public-data.bls_qcew.1998*`
WHERE
  geoid = (SELECT geo_id FROM geo)