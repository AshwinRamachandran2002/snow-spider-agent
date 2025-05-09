/*  The query finds the reference sequence with the greatest
    “variant density” (number of variants divided by sequence length). */

WITH variant_counts AS (
    SELECT 
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
)

SELECT 
    r."name" AS "reference_sequence_with_highest_variant_density"
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN variant_counts v
  ON r."name" = v."reference_name"
ORDER BY v."variant_count" / r."length" DESC NULLS LAST
LIMIT 1;