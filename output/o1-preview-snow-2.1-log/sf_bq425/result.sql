SELECT
    sub."chembl_id",
    sub."trade_name",
    sub."approval_date"
FROM (
    SELECT
        m."chembl_id",
        p."trade_name",
        p."approval_date",
        ROW_NUMBER() OVER (
            PARTITION BY m."chembl_id"
            ORDER BY p."approval_date" DESC
        ) AS rn
    FROM
        "EBI_CHEMBL"."EBI_CHEMBL"."MOLECULE_DICTIONARY_23" m
    JOIN
        "EBI_CHEMBL"."EBI_CHEMBL"."FORMULATIONS_23" f
            ON m."molregno" = f."molregno"
    JOIN
        "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_23" p
            ON f."product_id" = p."product_id"
    WHERE
        p."applicant_full_name" ILIKE '%Sanofi%' AND p."applicant_full_name" ILIKE '%Aventis%'
) sub
WHERE
    sub.rn = 1
ORDER BY
    sub."approval_date" DESC NULLS LAST;