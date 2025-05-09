SELECT
    "trade_name",
    MAX("approval_date") AS "most_recent_approval_date"
FROM (
    SELECT "trade_name", "approval_date", "applicant_full_name"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_26"
    UNION ALL
    SELECT "trade_name", "approval_date", "applicant_full_name"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_29"
    UNION ALL
    SELECT "trade_name", "approval_date", "applicant_full_name"
    FROM "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_33"
) AS p
WHERE UPPER(p."applicant_full_name") LIKE '%SANOFI%'
  AND UPPER(p."applicant_full_name") LIKE '%AVENTIS%'
GROUP BY "trade_name"
ORDER BY "trade_name" ASC NULLS LAST;