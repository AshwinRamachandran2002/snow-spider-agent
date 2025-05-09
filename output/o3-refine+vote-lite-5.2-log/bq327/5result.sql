SELECT COUNT(*) AS zero_value_records
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'        -- Russia
  AND value = 0                   -- value equals 0 (NULLs automatically excluded)