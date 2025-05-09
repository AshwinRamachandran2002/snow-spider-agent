SELECT
  trade_name,
  MAX(DATE(TIMESTAMP(approval_date))) AS latest_approval_date
FROM `bigquery-public-data.ebi_chembl.products_23`
WHERE REGEXP_CONTAINS(
        LOWER(applicant_full_name),
        r'^sanofi[\s-]*aventis(\b|$)'
      )                                   -- company matches “Sanofi Aventis” exactly (ignoring spaces / hyphen & case)
GROUP BY trade_name
ORDER BY trade_name;