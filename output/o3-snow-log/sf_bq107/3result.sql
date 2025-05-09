WITH ref_longest AS (
    SELECT 
        "name"   AS ref_name,
        "length" AS ref_length
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_count AS (
    SELECT 
        COUNT(DISTINCT v."variant_id") AS var_cnt
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN ref_longest rl
      ON v."reference_name" = rl.ref_name
    CROSS JOIN LATERAL FLATTEN(INPUT => v."call")  c
    CROSS JOIN LATERAL FLATTEN(INPUT => c.value:"genotype") g
    WHERE g.value::INT > 0
)
SELECT 
    var_cnt::FLOAT / rl.ref_length AS variant_density
FROM variant_count, ref_longest rl;