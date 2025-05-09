-- 1) Find the BRCA1 genomic span (min start, max end)
-- 2) Inside that span keep only missense variants
-- 3) Order their Protein_position numerically and return the smallest one
WITH gene_region AS (
  SELECT
    MIN(g.start_position) AS min_start,
    MAX(g.end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS vep
  WHERE vep.SYMBOL = 'BRCA1'
)

SELECT DISTINCT
  vep.Protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
JOIN gene_region r
  ON g.start_position BETWEEN r.min_start AND r.max_end
CROSS JOIN UNNEST(g.alternate_bases) AS alt
CROSS JOIN UNNEST(alt.vep)           AS vep
WHERE vep.Consequence LIKE '%missense_variant%'
  AND vep.Protein_position IS NOT NULL
ORDER BY SAFE_CAST(REGEXP_EXTRACT(vep.Protein_position, r'^\d+') AS INT64)
LIMIT 1;