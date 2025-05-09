WITH longest_ref AS (   -- longest reference sequence
    SELECT
        "name"   AS REFERENCE_NAME,
        "length" AS REFERENCE_LENGTH
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_positions AS (  -- distinct variant sites with any non-zero genotype
    SELECT
        v."reference_name" AS REFERENCE_NAME,
        COUNT(DISTINCT v."start") AS VARIANT_COUNT
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN longest_ref r
      ON v."reference_name" = r.REFERENCE_NAME
    , LATERAL FLATTEN(input => v."call")            c
    , LATERAL FLATTEN(input => c.value:"genotype")  g
    WHERE g.value::NUMBER > 0                      -- non-reference allele present
    GROUP BY v."reference_name"
)
SELECT
    r.REFERENCE_NAME,
    (vp.VARIANT_COUNT / r.REFERENCE_LENGTH) AS VARIANT_DENSITY
FROM longest_ref r
LEFT JOIN variant_positions vp
  ON vp.REFERENCE_NAME = r.REFERENCE_NAME;