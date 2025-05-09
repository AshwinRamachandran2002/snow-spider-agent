WITH brca_bounds AS (   -- region covered by any BRCA1 annotation
  SELECT
    MIN(t.start_position) AS region_start,
    MAX(t.end_position)   AS region_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN UNNEST(t.alternate_bases) AS ab
  CROSS JOIN UNNEST(ab.vep)           AS v
  WHERE v.SYMBOL = 'BRCA1'
),
missense_proteins AS (  -- missense Protein_position values within that region
  SELECT DISTINCT
    v.Protein_position,
    SAFE_CAST(REGEXP_EXTRACT(v.Protein_position, r'^\d+') AS INT64) AS protein_pos_num
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN brca_bounds AS b
  CROSS JOIN UNNEST(t.alternate_bases) AS ab
  CROSS JOIN UNNEST(ab.vep)            AS v
  WHERE t.start_position BETWEEN b.region_start AND b.region_end
    AND v.Consequence LIKE '%missense_variant%'
    AND v.Protein_position IS NOT NULL
)
SELECT Protein_position
FROM missense_proteins
ORDER BY protein_pos_num
LIMIT 1;