WITH gene_region AS (
  -- boundaries of any BRCA1‑annotated variant on chr17
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
  CROSS JOIN UNNEST(t.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS v
  WHERE v.SYMBOL = 'BRCA1'
)

SELECT DISTINCT
  v.Protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
CROSS JOIN UNNEST(t.alternate_bases) AS alt
CROSS JOIN UNNEST(alt.vep)           AS v
JOIN gene_region g
  ON t.start_position BETWEEN g.min_start AND g.max_end
WHERE v.Consequence LIKE '%missense_variant%'           -- keep only missense
  AND v.Protein_position IS NOT NULL                    -- must have position
ORDER BY SAFE_CAST(REGEXP_EXTRACT(v.Protein_position, r'^\d+') AS INT64)
LIMIT 1;