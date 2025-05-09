WITH variant_counts AS (
    SELECT
        "reference_name",
        COUNT(*) AS "variant_count"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
    GROUP BY "reference_name"
)
SELECT
    r."name" AS reference_sequence_name
FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703 r
JOIN variant_counts vc
      ON vc."reference_name" = r."name"
ORDER BY (vc."variant_count"::FLOAT / r."length") DESC NULLS LAST
LIMIT 1;