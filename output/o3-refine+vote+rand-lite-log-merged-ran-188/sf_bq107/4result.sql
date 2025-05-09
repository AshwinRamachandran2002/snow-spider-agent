WITH longest_ref AS (      -- reference sequence with the greatest length
    SELECT 
        "name"   AS reference_name,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),                                                            
qualified_variants AS (     -- variants on that reference having ≥1 genotype > 0
    SELECT DISTINCT v."variant_id"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN longest_ref r
      ON v."reference_name" = r.reference_name
    , LATERAL FLATTEN(input => v."call")            c        -- expand calls
    , LATERAL FLATTEN(input => c.value:"genotype")  g        -- expand genotypes
    WHERE g.value::INT > 0                                   
)
SELECT
    r.reference_name,
    r."length"                         AS reference_length,
    COUNT(q."variant_id")              AS variant_count,
    COUNT(q."variant_id") / r."length"::FLOAT AS variant_density
FROM longest_ref r
LEFT JOIN qualified_variants q ON 1 = 1
GROUP BY r.reference_name, r."length";