SELECT
    "trade_name",
    MAX("approval_date") AS "latest_approval_date"
FROM EBI_CHEMBL.EBI_CHEMBL."PRODUCTS_23"
WHERE SUBSTR(
          REPLACE(
              REPLACE(LOWER("applicant_full_name"), ' ', ''), 
          '-', ''),
      1, 13) = 'sanofiaventis'
GROUP BY "trade_name"
ORDER BY "latest_approval_date" DESC NULLS LAST;