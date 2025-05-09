-- Top three debt indicators for Russia by their highest recorded values
WITH ru_debt AS (
  SELECT
    indicator_code,
    MAX(value) AS max_value
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE country_code = 'RUS'      -- Russia
    AND value IS NOT NULL         -- exclude missing values
  GROUP BY indicator_code
)

SELECT
  rd.indicator_code,
  ss.indicator_name,
  rd.max_value
FROM ru_debt AS rd
JOIN `bigquery-public-data.world_bank_intl_debt.series_summary` AS ss
  ON rd.indicator_code = ss.series_code
ORDER BY rd.max_value DESC
LIMIT 3;