SELECT
  trade_name,
  MAX(CAST(SUBSTR(approval_date, 1, 10) AS DATE)) AS latest_approval_date
FROM `bigquery-public-data.ebi_chembl.products_23`
WHERE REGEXP_REPLACE(LOWER(applicant_full_name), r'[^a-z]', '') LIKE 'sanofiaventis%'
GROUP BY trade_name
ORDER BY trade_name;