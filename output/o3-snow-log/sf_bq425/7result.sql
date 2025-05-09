SELECT
    "trade_name"                                   AS "molecule",
    MAX(TO_TIMESTAMP_NTZ("approval_date"))         AS "latest_approval_date"
FROM
    EBI_CHEMBL.EBI_CHEMBL.PRODUCTS_23
WHERE
    REGEXP_REPLACE(LOWER("applicant_full_name"), '[^a-z]', '') LIKE '%sanofiaventis%'
GROUP BY
    "trade_name"
ORDER BY
    "latest_approval_date" DESC NULLS LAST;