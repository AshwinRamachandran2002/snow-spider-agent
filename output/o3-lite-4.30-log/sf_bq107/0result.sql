WITH longest_ref AS (
    SELECT "name" AS "reference_name",
           "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC
    LIMIT 1
),
present_variants AS (
    SELECT
        v."reference_name",
        COUNT(DISTINCT v."variant_id") AS "present_variant_cnt"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v,
         LATERAL FLATTEN(input => v."call") f,
         LATERAL FLATTEN(input => f.value:"genotype") g
    WHERE TRY_TO_NUMBER(g.value::STRING) > 0
    GROUP BY v."reference_name"
)
SELECT
    TO_DECIMAL(p."present_variant_cnt" / l."length", 38, 4) AS "variant_density"
FROM longest_ref l
LEFT JOIN present_variants p
       ON l."reference_name" = p."reference_name";