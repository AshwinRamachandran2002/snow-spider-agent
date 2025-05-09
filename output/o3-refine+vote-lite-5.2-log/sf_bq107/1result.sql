WITH longest_ref AS (      -- contig with the greatest length
    SELECT
        "name"   AS ref_name,
        "length" AS ref_length
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_REFERENCE_201703
    ORDER BY "length" DESC NULLS LAST
    LIMIT 1
),
variant_ids AS (           -- variants on that contig having any non‑zero genotype
    SELECT DISTINCT
        v."variant_id"
    FROM GENOMICS_CANNABIS.GENOMICS_CANNABIS.MNPR01_201703 v
    JOIN longest_ref lr
          ON v."reference_name" = lr.ref_name
    CROSS JOIN LATERAL FLATTEN(input => v."call")      c
    CROSS JOIN LATERAL FLATTEN(input => c.value:"genotype") g
    WHERE g.value::INT > 0
)

SELECT
    lr.ref_name,
    lr.ref_length,
    COUNT(*)                                         AS num_variants,
    COUNT(*) / lr.ref_length::FLOAT                  AS variant_density
FROM longest_ref lr
JOIN variant_ids
      ON 1 = 1
GROUP BY
    lr.ref_name,
    lr.ref_length;