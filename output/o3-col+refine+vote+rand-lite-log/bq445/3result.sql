WITH brca1_bounds AS (
  -- 1) Genomic span of all BRCA1-annotated variants
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS vep
  WHERE vep.SYMBOL = 'BRCA1'
),
missense AS (
  -- 2) All missense variants whose coordinates fall inside that BRCA1 span
  SELECT DISTINCT
    CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64) AS Protein_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
  JOIN brca1_bounds                         AS b
    ON g.start_position BETWEEN b.min_start AND b.max_end
  CROSS JOIN UNNEST(g.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS vep
  WHERE vep.Consequence LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
-- 3) Smallest (earliest) protein position
SELECT Protein_position
FROM missense
ORDER BY Protein_position
LIMIT 1;