SELECT
    "chembl_id",
    "trade_name",
    "approval_date"
FROM (
    SELECT
        m."chembl_id",
        p."trade_name",
        p."approval_date",
        ROW_NUMBER() OVER (PARTITION BY m."chembl_id" ORDER BY p."approval_date" DESC) AS rn
    FROM
        "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_23" p
        JOIN "EBI_CHEMBL"."EBI_CHEMBL"."FORMULATIONS_23" f ON p."product_id" = f."product_id"
        JOIN "EBI_CHEMBL"."EBI_CHEMBL"."MOLECULE_DICTIONARY_23" m ON f."molregno" = m."molregno"
    WHERE
        p."applicant_full_name" ILIKE '%SANOFI%' AND p."applicant_full_name" ILIKE '%AVENTIS%'
) sub
WHERE rn = 1
ORDER BY "approval_date" DESC NULLS LAST;