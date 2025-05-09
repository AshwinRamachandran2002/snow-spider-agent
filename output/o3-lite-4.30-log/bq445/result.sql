WITH brca1_bounds AS (
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN UNNEST(t.alternate_bases) AS ab
  CROSS JOIN UNNEST(ab.vep)            AS v
  WHERE v.SYMBOL = 'BRCA1'
)
SELECT DISTINCT v.Protein_position AS Protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
CROSS JOIN UNNEST(t.alternate_bases) AS ab
CROSS JOIN UNNEST(ab.vep)            AS v
JOIN brca1_bounds b
  ON t.start_position >= b.min_start
 AND t.end_position   <= b.max_end
WHERE v.Consequence LIKE '%missense_variant%'
ORDER BY SAFE_CAST(REGEXP_EXTRACT(v.Protein_position, r'^\d+') AS INT64)
LIMIT 1;