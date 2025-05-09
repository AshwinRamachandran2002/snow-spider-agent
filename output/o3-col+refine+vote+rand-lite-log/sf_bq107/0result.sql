/*  Variant density (variants per bp) on the longest cannabis reference sequence  */
WITH longest_ref AS (
    SELECT "name"   AS ref_name,
           "length" AS ref_length
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
present_variants AS (
    /* keep each variant once if ANY genotype allele > 0 */
    SELECT DISTINCT v."variant_id"
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v,
           LATERAL FLATTEN( INPUT => v."call" ) f,
           longest_ref lr
    WHERE  v."reference_name" = lr.ref_name
      AND (  COALESCE(f.value:"genotype"[0]::INTEGER,0) > 0
          OR COALESCE(f.value:"genotype"[1]::INTEGER,0) > 0
          OR COALESCE(f.value:"genotype"[2]::INTEGER,0) > 0 )
)
SELECT lr.ref_name                       AS "reference_name",
       lr.ref_length                     AS "reference_length",
       COUNT(pv."variant_id")            AS "num_variants",
       COUNT(pv."variant_id") / lr.ref_length::FLOAT
                                         AS "variant_density_per_bp"
FROM   longest_ref lr
LEFT  JOIN present_variants pv ON 1 = 1
GROUP BY lr.ref_name, lr.ref_length;