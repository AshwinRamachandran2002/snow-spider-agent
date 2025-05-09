WITH longest_reference AS (
    /* reference (contig) with the greatest length */
    SELECT 
        "name"   AS "reference_name",
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_count AS (
    /* count variants on that reference that have at least one non-zero genotype */
    SELECT 
        COUNT(DISTINCT v."variant_id") AS "n_variants"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 v
    JOIN longest_reference lr
      ON v."reference_name" = lr."reference_name"
    , LATERAL FLATTEN(input => v."call")      c        -- each call object
    , LATERAL FLATTEN(input => c.value:"genotype") g   -- each genotype allele
    WHERE g.value::INTEGER > 0                       -- at least one allele > 0
)
SELECT 
    lr."reference_name",
    lr."length"                                 AS "reference_length",
    vc."n_variants",
    ROUND(vc."n_variants" / lr."length"::FLOAT, 4) AS "variant_density"
FROM longest_reference lr
CROSS JOIN variant_count vc;