-- Country with the highest share of people younger than 25 in 2017
WITH under25 AS (
  SELECT
    country_code,
    SUM(
          population_age_0  + population_age_1  + population_age_2  + population_age_3  + population_age_4 +
          population_age_5  + population_age_6  + population_age_7  + population_age_8  + population_age_9 +
          population_age_10 + population_age_11 + population_age_12 + population_age_13 + population_age_14 +
          population_age_15 + population_age_16 + population_age_17 + population_age_18 + population_age_19 +
          population_age_20 + population_age_21 + population_age_22 + population_age_23 + population_age_24
        ) AS under25_total
  FROM `bigquery-public-data.census_bureau_international.midyear_population_age_sex`
  WHERE year = 2017
  GROUP BY country_code
)

SELECT
  p.country_name AS highest_under25_country,
  ROUND(100 * u.under25_total / p.midyear_population, 2) AS percentage_under25
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS p
JOIN under25 AS u
USING (country_code)
WHERE p.year = 2017
ORDER BY percentage_under25 DESC
LIMIT 1;