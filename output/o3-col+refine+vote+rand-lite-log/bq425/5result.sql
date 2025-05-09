SELECT
  trade_name,
  MAX(CAST(approval_date AS DATE)) AS latest_approval_date
FROM
  `bigquery-public-data.ebi_chembl.products_23`
WHERE
  -- Strip all non-letters ; keep companies whose cleaned name starts with “SANOFIAVENTIS”
  REGEXP_REPLACE(UPPER(applicant_full_name), r'[^A-Z]', '') LIKE 'SANOFIAVENTIS%'
GROUP BY
  trade_name
ORDER BY
  trade_name;