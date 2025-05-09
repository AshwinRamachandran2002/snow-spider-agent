WITH pop_rank AS (
  SELECT
    a.geo_id,
    ROW_NUMBER() OVER (
        ORDER BY SAFE_DIVIDE(b.total_pop - a.total_pop, a.total_pop) DESC, a.geo_id
    ) AS pop_rnk
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` a
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` b
  USING (geo_id)
  WHERE SUBSTR(a.geo_id,1,5) = '36047'
    AND a.total_pop >= 1000
    AND b.total_pop >= 1000
),
income_rank AS (
  SELECT
    a.geo_id,
    ROW_NUMBER() OVER (
        ORDER BY (b.median_income - a.median_income) DESC, a.geo_id
    ) AS inc_rnk
  FROM `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` a
  JOIN `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` b
  USING (geo_id)
  WHERE SUBSTR(a.geo_id,1,5) = '36047'
    AND a.total_pop >= 1000
    AND b.total_pop >= 1000
)
SELECT
  p.geo_id AS census_tract
FROM pop_rank AS p
JOIN income_rank AS i
ON p.geo_id = i.geo_id
WHERE p.pop_rnk <= 20
  AND i.inc_rnk <= 20
ORDER BY census_tract;