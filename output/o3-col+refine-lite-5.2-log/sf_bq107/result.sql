WITH longest_ref AS (
    SELECT 
        "name"   AS "reference_name",
        "length" AS "reference_length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
), variants AS (
    SELECT 
        COUNT(DISTINCT m."variant_id") AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 m
    JOIN longest_ref r
      ON m."reference_name" = r."reference_name"
    , LATERAL FLATTEN(input => m."call")            f
    , LATERAL FLATTEN(input => f.value:"genotype")  g
    WHERE g.value::INT > 0           -- at least one allele > 0
)
SELECT 
    ROUND("variant_count" / "reference_length", 4) AS "variant_density"
FROM variants, longest_ref;