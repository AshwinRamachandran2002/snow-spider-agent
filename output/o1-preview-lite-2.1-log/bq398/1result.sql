SELECT
  `indicator_name`,
  `value` AS Total_Debt_Value_USD
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data`
WHERE
  `country_code` = 'RUS'
  AND LOWER(`indicator_name`) LIKE '%debt%'
  AND `year` = (
    SELECT
      MAX(`year`)
    FROM
      `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE
      `country_code` = 'RUS'
      AND `value` IS NOT NULL
      AND LOWER(`indicator_name`) LIKE '%debt%'
  )
ORDER BY
  `value` DESC
LIMIT 3