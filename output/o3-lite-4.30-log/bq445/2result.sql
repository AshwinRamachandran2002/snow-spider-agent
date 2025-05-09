WITH brca1_span AS (
  -- find genomic boundaries for variants annotated to BRCA1
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`
  WHERE EXISTS (
    SELECT 1
    FROM UNNEST(alternate_bases) AS ab
    CROSS JOIN UNNEST(ab.vep)    AS v
    WHERE v.SYMBOL = 'BRCA1'
  )
)
SELECT DISTINCT v.Protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
CROSS JOIN UNNEST(t.alternate_bases) AS ab
CROSS JOIN UNNEST(ab.vep)            AS v
CROSS JOIN brca1_span                AS s
WHERE t.start_position BETWEEN s.min_start AND s.max_end
  AND v.SYMBOL = 'BRCA1'
  AND v.Consequence LIKE '%missense_variant%'
  AND v.Protein_position IS NOT NULL
ORDER BY CAST(SPLIT(v.Protein_position, '/')[SAFE_OFFSET(0)] AS INT64)
LIMIT 1;