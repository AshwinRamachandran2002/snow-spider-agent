WITH brca1_region AS (
  -- Find genomic span of every variant whose VEP annotation carries the BRCA1 symbol
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep_entry
  WHERE vep_entry.SYMBOL = 'BRCA1'
),
missense_positions AS (
  -- Inside that span keep only missense variants and extract their numeric Protein_position
  SELECT DISTINCT
    CAST(SPLIT(vep_entry.Protein_position,'/')[SAFE_OFFSET(0)] AS INT64) AS protein_pos
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  JOIN brca1_region r
    ON t.start_position BETWEEN r.min_start AND r.max_end
  ,UNNEST(t.alternate_bases) AS alt
  ,UNNEST(alt.vep)           AS vep_entry
  WHERE vep_entry.Consequence LIKE '%missense_variant%'
)
-- Return the smallest Protein_position
SELECT protein_pos AS Protein_position
FROM missense_positions
ORDER BY protein_pos
LIMIT 1;