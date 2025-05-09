SELECT
    "trade_name"                 AS "molecule_trade_name",
    MAX("approval_date")         AS "most_recent_approval_date"
FROM
    EBI_CHEMBL.EBI_CHEMBL.PRODUCTS_23
WHERE
    UPPER("applicant_full_name") LIKE '%SANOFI%'
    AND UPPER("applicant_full_name") LIKE '%AVENTIS%'
GROUP BY
    "trade_name"
ORDER BY
    "most_recent_approval_date" DESC NULLS LAST;