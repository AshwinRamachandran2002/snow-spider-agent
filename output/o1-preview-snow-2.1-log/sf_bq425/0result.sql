SELECT md."chembl_id", p."trade_name", MAX(p."approval_date") AS "approval_date"
FROM "EBI_CHEMBL"."EBI_CHEMBL"."MOLECULE_DICTIONARY_23" md
JOIN "EBI_CHEMBL"."EBI_CHEMBL"."FORMULATIONS_23" f ON md."molregno" = f."molregno"
JOIN "EBI_CHEMBL"."EBI_CHEMBL"."PRODUCTS_23" p ON f."product_id" = p."product_id"
WHERE LOWER(p."applicant_full_name") LIKE '%sanofi%' OR LOWER(p."applicant_full_name") LIKE '%aventis%'
   OR LOWER(p."innovator_company") LIKE '%sanofi%' OR LOWER(p."innovator_company") LIKE '%aventis%'
GROUP BY md."chembl_id", p."trade_name";