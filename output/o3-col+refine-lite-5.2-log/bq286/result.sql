WITH wy AS (
  SELECT
    name,
    SUM(number) AS wy_female_2021
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE state = 'WY'
    AND gender = 'F'
    AND year = 2021
  GROUP BY name
),
usa AS (
  SELECT
    name,
    SUM(number) AS usa_female_2021
  FROM `bigquery-public-data.usa_names.usa_1910_current`
  WHERE gender = 'F'
    AND year = 2021
  GROUP BY name
)
SELECT
  wy.name AS most_popular_in_wy_by_share
FROM wy
JOIN usa USING (name)
ORDER BY
  SAFE_DIVIDE(wy.wy_female_2021, usa.usa_female_2021) DESC,
  wy.wy_female_2021 DESC
LIMIT 1;