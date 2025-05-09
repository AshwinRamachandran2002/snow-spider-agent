WITH longest_ref AS (
    SELECT 
        "name"   AS "reference_name",
        "length" AS "reference_length"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
), variant_positions AS (
    SELECT 
        COUNT(DISTINCT t."start") AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703 t,
         longest_ref lr,
         LATERAL FLATTEN(input => t."call")            c,
         LATERAL FLATTEN(input => c.value:"genotype")  g
    WHERE t."reference_name" = lr."reference_name"
      AND g.value::INTEGER > 0
)
SELECT 
    lr."reference_name",
    lr."reference_length",
    vp."variant_count",
    vp."variant_count"::FLOAT / lr."reference_length" AS "variant_density"
FROM longest_ref lr
JOIN variant_positions vp ON 1=1;