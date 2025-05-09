WITH longest AS (                       -- 1) longest reference sequence
    SELECT "name"   AS ref_name,
           "length" AS ref_len
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER  BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_tally AS (                      -- 2) variants on that reference with ≥1 genotype > 0
    SELECT COUNT(DISTINCT t."variant_id")              AS variant_ct,
           MAX(l.ref_len)                              AS ref_len
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 t
    JOIN   longest l
           ON t."reference_name" = l.ref_name
         , LATERAL FLATTEN(input => t."call") c
    WHERE  (c.value:"genotype"[0]::INT > 0
            OR c.value:"genotype"[1]::INT > 0)
)
SELECT ROUND(variant_ct / ref_len, 4) AS variant_density   -- 3) density = variants ÷ length
FROM   variant_tally;