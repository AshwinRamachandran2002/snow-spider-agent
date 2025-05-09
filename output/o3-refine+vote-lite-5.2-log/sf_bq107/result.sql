WITH longest_ref AS (
    -- 1. find the reference sequence with the greatest length
    SELECT "name",
           "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC
    LIMIT 1
),
variant_totals AS (
    -- 2. count distinct variants on that reference that have
    --    at least one genotype call > 0 (i.e., the allele is present)
    SELECT   v."reference_name",
             COUNT(DISTINCT v."variant_id")               AS num_variants
    FROM     GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN     longest_ref lr
           ON v."reference_name" = lr."name"
    ,        LATERAL FLATTEN(input => v."call")           c
    ,        LATERAL FLATTEN(input => c.value:"genotype") g
    WHERE    g.value::int > 0
    GROUP BY v."reference_name"
)
-- 3. compute variant density (variants per base)
SELECT  lr."name"                       AS reference_name,
        lr."length",
        vt.num_variants,
        ROUND(vt.num_variants / lr."length", 4) AS variant_density
FROM    longest_ref  lr
LEFT JOIN variant_totals vt
       ON vt."reference_name" = lr."name";