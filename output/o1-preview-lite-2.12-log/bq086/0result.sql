SELECT
  wb.country AS country_name,
  ROUND((covid.cumulative_confirmed / wb.year_2018) * 100, 4) AS confirmed_cases_percentage
FROM
  (
    SELECT
      iso_3166_1_alpha_3 AS country_code,
      MAX(cumulative_confirmed) AS cumulative_confirmed
    FROM
      `bigquery-public-data.covid19_open_data.covid19_open_data`
    WHERE
      date = '2020-06-30'
      AND aggregation_level = 0
      AND cumulative_confirmed IS NOT NULL
    GROUP BY
      iso_3166_1_alpha_3
  ) AS covid
JOIN
  `bigquery-public-data.world_bank_global_population.population_by_country` AS wb
ON
  wb.country_code = covid.country_code
WHERE
  wb.year_2018 IS NOT NULL;