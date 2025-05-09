WITH longest_reference AS (      -- reference entry with the maximum length
    SELECT
        "name"   AS reference_name,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_ct AS (                  -- variants having at least one genotype > 0
    SELECT
        COUNT(DISTINCT v."variant_id") AS variant_count
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 v
    JOIN longest_reference lr
      ON v."reference_name" = lr.reference_name
    CROSS JOIN LATERAL FLATTEN(input => v."call")  c
    CROSS JOIN LATERAL FLATTEN(input => c.value:"genotype") g
    WHERE g.value::int > 0
)
SELECT
    lr.reference_name,
    lr."length"                       AS reference_length,
    vc.variant_count,
    vc.variant_count / lr."length"    AS variant_density
FROM longest_reference lr
CROSS JOIN variant_ct vc;