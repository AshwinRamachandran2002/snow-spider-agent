WITH longest_ref AS (
    SELECT 
        "name"   AS reference_name,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703"
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variants_for_longest AS (
    SELECT 
        t."reference_name",
        COUNT(DISTINCT t."variant_id") AS variant_cnt
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_TRANSCRIPTOME_201703" t,
         LATERAL FLATTEN(input => t."call") gen
    WHERE
        gen.value:"genotype"[0]::INTEGER > 0 
        OR gen.value:"genotype"[1]::INTEGER > 0
    GROUP BY t."reference_name"
)
SELECT 
    ROUND(v.variant_cnt / l."length", 4) AS variant_density
FROM longest_ref l
LEFT JOIN variants_for_longest v
       ON l.reference_name = v."reference_name";