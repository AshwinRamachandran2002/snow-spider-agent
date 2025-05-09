WITH pop_top20 AS (
  SELECT 
    t2011.geo_id,
    ROUND(t2011.total_pop, 4) AS pop2011,
    ROUND(t2018.total_pop, 4) AS pop2018,
    ROUND(t2018.total_pop - t2011.total_pop, 4) AS pop_change
  FROM
    `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` AS t2011
  JOIN
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t2018
  ON
    t2011.geo_id = t2018.geo_id
  WHERE
    t2011.geo_id LIKE '36047%'  -- Census tracts in Kings County, NY
    AND t2011.total_pop > 1000
    AND t2018.total_pop > 1000
    AND (t2018.total_pop - t2011.total_pop) > 0  -- Positive population increase
  ORDER BY
    pop_change DESC
  LIMIT 20
),

income_top20 AS (
  SELECT
    t2011.geo_id,
    ROUND(t2011.median_income, 4) AS income2011,
    ROUND(t2018.median_income, 4) AS income2018,
    ROUND(t2018.median_income - t2011.median_income, 4) AS income_change
  FROM
    `bigquery-public-data.census_bureau_acs.censustract_2011_5yr` AS t2011
  JOIN
    `bigquery-public-data.census_bureau_acs.censustract_2018_5yr` AS t2018
  ON
    t2011.geo_id = t2018.geo_id
  WHERE
    t2011.geo_id LIKE '36047%'  -- Census tracts in Kings County, NY
    AND t2011.total_pop > 1000
    AND t2018.total_pop > 1000
    AND t2011.median_income IS NOT NULL
    AND t2018.median_income IS NOT NULL
    AND (t2018.median_income - t2011.median_income) > 0  -- Positive income increase
  ORDER BY
    income_change DESC
  LIMIT 20
)

SELECT
  pop_top20.geo_id,
  pop_top20.pop2011,
  pop_top20.pop2018,
  pop_top20.pop_change,
  income_top20.income2011,
  income_top20.income2018,
  income_top20.income_change
FROM
  pop_top20
INNER JOIN
  income_top20
ON
  pop_top20.geo_id = income_top20.geo_id;