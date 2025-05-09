WITH gene_region AS (
  -- 1. find genomic span of all variants that have a BRCA1 VEP annotation
  SELECT
    MIN(start_position) AS region_start,
    MAX(end_position)   AS region_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`   t,
       UNNEST(t.alternate_bases)                     AS ab,
       UNNEST(ab.vep)                                AS vep
  WHERE vep.SYMBOL = 'BRCA1'
),
missense AS (
  -- 2. within that span, collect Protein_position values whose consequence is missense_variant
  SELECT DISTINCT
    vep.Protein_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
  CROSS JOIN gene_region gr
  JOIN UNNEST(t.alternate_bases) AS ab
  JOIN UNNEST(ab.vep)            AS vep
  WHERE t.start_position BETWEEN gr.region_start AND gr.region_end
    AND vep.Consequence LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
-- 3. smallest (earliest) protein position
SELECT
  Protein_position
FROM missense
ORDER BY SAFE_CAST(REGEXP_EXTRACT(Protein_position, r'^\d+') AS INT64)
LIMIT 1;