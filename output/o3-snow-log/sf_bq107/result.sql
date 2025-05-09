WITH longest_ref AS (
    SELECT 
        "name",
        "length"
    FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_REFERENCE_201703"
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_counts AS (
    SELECT
        v."reference_name",
        COUNT(DISTINCT v."variant_id") AS variant_count
    FROM "GENOMICS_CANNABIS"."GENOMICS_CANNABIS"."MNPR01_TRANSCRIPTOME_201703" v,
         LATERAL FLATTEN(input => v."call") c,
         LATERAL FLATTEN(input => c.value:"genotype") g,
         longest_ref r
    WHERE v."reference_name" = r."name"
      AND g.value::int > 0          -- at least one non-reference allele
    GROUP BY v."reference_name"
)
SELECT
    r."name"          AS reference_name,
    r."length"        AS reference_length,
    vc.variant_count,
    ROUND(vc.variant_count / r."length", 4) AS variant_density
FROM longest_ref r
LEFT JOIN variant_counts vc
       ON vc."reference_name" = r."name";