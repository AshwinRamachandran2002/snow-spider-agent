SELECT 
    p."id" AS "packaging_id", 
    p."name", 
    ROUND(SUM(pr0."qty" * COALESCE(pr1."qty", 1) * COALESCE(pr2."qty", 1) * COALESCE(pr3."qty", 1)), 4) AS "total_quantity"
FROM 
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr0
LEFT JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr1 
    ON pr0."contains_id" = pr1."packaging_id"
LEFT JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr2 
    ON pr1."contains_id" = pr2."packaging_id"
LEFT JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING_RELATIONS" pr3 
    ON pr2."contains_id" = pr3."packaging_id"
JOIN 
    "ORACLE_SQL"."ORACLE_SQL"."PACKAGING" p 
    ON pr0."packaging_id" = p."id"
GROUP BY 
    p."id", p."name"
HAVING
    ROUND(SUM(pr0."qty" * COALESCE(pr1."qty", 1) * COALESCE(pr2."qty", 1) * COALESCE(pr3."qty", 1)), 4) > 500
ORDER BY "total_quantity" DESC NULLS LAST;