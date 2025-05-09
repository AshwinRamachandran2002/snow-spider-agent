/*  Variant density on the single longest reference scaffold            */
/*  – a variant is counted once if ANY sample call has genotype > 0      */

WITH longest AS (           -- find the longest reference record
    SELECT "name"  AS "reference_name",
           "length"
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_REFERENCE_201703"
    ORDER  BY "length" DESC NULLS LAST
    LIMIT  1
),                                                   -- distinct non-reference variants
variants AS (                                       
    SELECT DISTINCT v."variant_id",
                    v."reference_name"
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS."MNPR01_201703"  v,
           LATERAL FLATTEN( INPUT => v."call")                  c,
           longest                                              l
    WHERE  v."reference_name" = l."reference_name"
      AND ( NVL( c.value:"genotype"[0]::NUMBER , 0) > 0
         OR NVL( c.value:"genotype"[1]::NUMBER , 0) > 0 )
)

SELECT  l."reference_name",
        l."length",
        COUNT(variants."variant_id")              AS "variant_count",
        COUNT(variants."variant_id") / l."length" AS "variant_density"
FROM    longest  l
LEFT JOIN variants
       ON l."reference_name" = variants."reference_name"
GROUP BY l."reference_name", l."length";