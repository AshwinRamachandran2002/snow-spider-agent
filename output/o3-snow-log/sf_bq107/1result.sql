-- variant density for the longest cannabis reference
WITH longest_ref AS (       -- 1. reference with the greatest length
    SELECT 
        "name"       AS reference_name ,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
qualified_variants AS (     -- 2. variants on that reference having ≥1 genotype > 0
    SELECT DISTINCT 
        v."variant_id"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 v
    JOIN longest_ref lr
          ON v."reference_name" = lr.reference_name
    ,     LATERAL FLATTEN( input => v."call")               c
    ,     LATERAL FLATTEN( input => c.value:"genotype")     g
    WHERE g.value::number > 0                               -- genotype > 0
)
-- 3. final density
SELECT 
    lr.reference_name,
    lr."length"                       AS reference_length,
    COUNT(qv."variant_id")            AS variant_count,
    COUNT(qv."variant_id") / lr."length" ::FLOAT  AS variant_density
FROM longest_ref          lr
LEFT JOIN qualified_variants qv  ON 1=1
GROUP BY lr.reference_name, lr."length";