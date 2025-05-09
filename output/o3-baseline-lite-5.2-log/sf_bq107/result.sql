WITH max_ref AS (
    /* 1.  Reference sequence having the greatest length                       */
    SELECT 
        "name"  AS reference_name ,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
)

SELECT
    mr.reference_name,
    mr."length"                                         AS reference_length,
    COUNT(DISTINCT v."variant_id")                      AS variant_count,
    COUNT(DISTINCT v."variant_id")::FLOAT / mr."length" AS variant_density
FROM               max_ref                                                mr
JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703               v
     ON v."reference_name" = mr.reference_name
CROSS JOIN LATERAL FLATTEN(input => v."call")                          c      -- each call object
CROSS JOIN LATERAL FLATTEN(input => c.value:"genotype")                g      -- each allele in genotype
WHERE g.value::INT > 0                                                        -- at least one allele > 0
GROUP BY mr.reference_name , mr."length";