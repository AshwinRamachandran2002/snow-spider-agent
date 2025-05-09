WITH longest_ref AS (
    SELECT 
        "name"   AS ref_name,
        "length" AS ref_length
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_counts AS (
    SELECT
        v."reference_name",
        COUNT(DISTINCT v."variant_id") AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN longest_ref lr
      ON v."reference_name" = lr.ref_name
    , LATERAL FLATTEN(input => v."call") c                    -- expand calls per variant
    , LATERAL FLATTEN(input => c.value:"genotype") g          -- expand alleles in genotype
    WHERE g.value::INTEGER > 0                                -- keep if any allele > 0
    GROUP BY v."reference_name"
)
SELECT
    lr.ref_name,
    lr.ref_length,
    COALESCE(vc.variant_count, 0) AS variant_count,
    ROUND(COALESCE(vc.variant_count, 0)::FLOAT / lr.ref_length, 4) AS variant_density
FROM longest_ref lr
LEFT JOIN variant_counts vc
       ON vc."reference_name" = lr.ref_name;