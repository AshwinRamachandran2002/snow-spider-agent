-- variant density = (# variants with any non-zero genotype) / reference length
WITH longest_ref AS (  -- 1. find the reference with the greatest length
    SELECT  "name",
            "length"
    FROM    GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703"
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variants AS (          -- 2. keep only variants on that reference
    SELECT  DISTINCT t."variant_id"
    FROM    GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_TRANSCRIPTOME_201703" t
            JOIN longest_ref r
              ON t."reference_name" = r."name"
            , LATERAL FLATTEN(input => t."call")                c   -- explode call array
            , LATERAL FLATTEN(input => c.value:"genotype")      g   -- explode genotype array
    WHERE   g.value::INTEGER > 0                               -- at least one allele > 0
)
SELECT  ROUND( (SELECT COUNT(*) FROM variants)::FLOAT
              / (SELECT "length" FROM longest_ref)
            , 4)                                                AS "variant_density";