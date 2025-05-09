-- List every genomic position on chr17 (gnomAD v2.1.1) where
--   • gene  = BRCA1,
--   • effect = missense_variant,
--   • ref    = 'C',
--   • alt    = 'T'.
-- Results are combined across the genomes and exomes releases.

SELECT DISTINCT start_position
FROM (
  -- gnomAD v2.1.1 genomes (chr17)
  SELECT g.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS alt_struct
  CROSS JOIN UNNEST(alt_struct.vep)    AS v
  WHERE g.reference_bases = 'C'
    AND alt_struct.alt   = 'T'
    AND (v.SYMBOL = 'BRCA1' OR v.Gene = 'ENSG00000012048')
    AND v.Consequence LIKE '%missense_variant%'

  UNION DISTINCT

  -- gnomAD v2.1.1 exomes (chr17)
  SELECT e.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS e
  CROSS JOIN UNNEST(e.alternate_bases) AS alt_struct
  CROSS JOIN UNNEST(alt_struct.vep)    AS v
  WHERE e.reference_bases = 'C'
    AND alt_struct.alt   = 'T'
    AND (v.SYMBOL = 'BRCA1' OR v.Gene = 'ENSG00000012048')
    AND v.Consequence LIKE '%missense_variant%'
)
ORDER BY start_position;