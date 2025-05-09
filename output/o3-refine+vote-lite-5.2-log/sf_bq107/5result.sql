WITH "longest_ref" AS (   -- reference having the greatest length
    SELECT 
        "name"   AS reference_name,
        "length" AS reference_length
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
"variants_with_call" AS ( -- variants on that reference with any non‑zero genotype
    SELECT DISTINCT
           v."variant_id"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN "longest_ref" r
      ON v."reference_name" = r.reference_name
        -- explode the calls and their genotype array
    ,   LATERAL FLATTEN(input => v."call")        fc
    ,   LATERAL FLATTEN(input => fc.value:"genotype") g
    WHERE g.value::NUMBER > 0                     -- at least one allele > 0
),
"variant_counts" AS (     -- how many such variants exist
    SELECT COUNT(*) AS variant_count
    FROM "variants_with_call"
)
SELECT
    r.reference_name,
    r.reference_length,
    vc.variant_count,
    vc.variant_count::FLOAT / r.reference_length AS variant_density
FROM "longest_ref"   r
CROSS JOIN "variant_counts" vc;