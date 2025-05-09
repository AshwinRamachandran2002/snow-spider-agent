-- Top three Russian debt indicators ranked by their highest recorded value
SELECT
  d.indicator_code,
  s.topic,
  d.indicator_name,
  MAX(d.value) AS max_value_usd
FROM `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
JOIN `bigquery-public-data.world_bank_intl_debt.series_summary` AS s
  ON d.indicator_code = s.series_code
WHERE d.country_code = 'RUS'
  AND d.value IS NOT NULL
GROUP BY d.indicator_code, s.topic, d.indicator_name
ORDER BY max_value_usd DESC
LIMIT 3;