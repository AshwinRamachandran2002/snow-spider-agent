-- Top 10 countries by total long-term external debt (current US$)
-- (using the World Development Indicators data and excluding countries without a region)
SELECT
  d.country_code,
  c.short_name AS country_name,
  SUM(d.value) AS total_long_term_debt_usd
FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS d
JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS c
  ON c.country_code = d.country_code
WHERE d.indicator_code = 'DT.DOD.DLXF.CD'   -- External debt stocks, long-term (current US$)
  AND d.value IS NOT NULL                   -- ignore missing values
  AND NOT IS_NAN(d.value)                   -- ignore NaN values
  AND c.region IS NOT NULL
  AND c.region <> ''                        -- exclude unspecified regions
GROUP BY d.country_code, c.short_name
ORDER BY total_long_term_debt_usd DESC
LIMIT 10;