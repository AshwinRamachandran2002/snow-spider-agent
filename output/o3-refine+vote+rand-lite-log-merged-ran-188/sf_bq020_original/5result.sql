SELECT
    r."name" AS "reference_sequence_with_highest_variant_density"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
) v
  ON v."reference_name" = r."name"
ORDER BY (v."variant_count" / r."length") DESC NULLS LAST
LIMIT 1;