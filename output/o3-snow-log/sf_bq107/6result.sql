WITH longest_ref AS (
    SELECT "name"  AS ref_name,
           "length"
    FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER  BY "length" DESC NULLS LAST
    LIMIT  1
),
variant_src AS (
    SELECT "reference_name",
           "start",
           "call"
    FROM (
          SELECT "reference_name",
                 "start",
                 "call"
          FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703
          UNION ALL
          SELECT "reference_name",
                 "start",
                 "call"
          FROM   GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_TRANSCRIPTOME_201703
    )
    WHERE  "reference_name" = (SELECT ref_name FROM longest_ref)
),
variant_positions AS (
    SELECT DISTINCT vs."start"
    FROM   variant_src vs,
           LATERAL FLATTEN(input => vs."call")         c,
           LATERAL FLATTEN(input => c.value:"genotype") g
    WHERE  g.value::INT > 0          -- at least one allele > 0
)
SELECT COUNT(*)                                   AS "variant_count",
       (SELECT "length" FROM longest_ref)         AS "reference_length",
       COUNT(*)::FLOAT / (SELECT "length"
                          FROM longest_ref)       AS "variant_density"
FROM   variant_positions;