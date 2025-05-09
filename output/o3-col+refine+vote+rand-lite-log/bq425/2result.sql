SELECT
  trade_name,
  MAX(PARSE_DATE('%Y-%m-%d', approval_date)) AS latest_approval_date
FROM `bigquery-public-data.ebi_chembl.products_23`
WHERE LOWER(applicant_full_name) LIKE '%sanofi%'
  AND LOWER(applicant_full_name) LIKE '%aventis%'
GROUP BY trade_name
ORDER BY trade_name;