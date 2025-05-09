SELECT
  covid.country_name,
  (covid.cumulative_confirmed / pop.population_2019) * 100 AS COVID_confirmed_percentage
FROM
  (
    SELECT
      iso_3166_1_alpha_3 AS country_code,
      country_name,
      cumulative_confirmed
    FROM
      `bigquery-public-data.covid19_open_data.covid19_open_data`
    WHERE
      date = '2020-06-30'
      AND aggregation_level = 0
      AND cumulative_confirmed IS NOT NULL
      AND iso_3166_1_alpha_3 IS NOT NULL
  ) AS covid
JOIN
  (
    SELECT
      country_code,
      MAX(value) AS population_2019
    FROM
      `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE
      indicator_code = 'SP.POP.TOTL'
      AND year = 2019
      AND value IS NOT NULL
    GROUP BY
      country_code
  ) AS pop
ON
  covid.country_code = pop.country_code
ORDER BY
  COVID_confirmed_percentage DESC;