WITH longest AS (
    SELECT 
        "name"  AS reference_name,
        "length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
), variants_present AS (
    SELECT DISTINCT
           t."variant_id",
           l."length"
    FROM longest l
    JOIN GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 t
      ON t."reference_name" = l.reference_name
    , LATERAL FLATTEN(input => t."call") c
    , LATERAL FLATTEN(input => c.value:"genotype") g
    WHERE g.value::INT > 0        -- genotype includes at least one non-reference allele
)
SELECT
    (SELECT reference_name FROM longest)      AS reference_name,
    MAX("length")                             AS reference_length,
    COUNT("variant_id")                       AS variant_count,
    COUNT("variant_id") / MAX("length")       AS variant_density
FROM variants_present;