-- Missense BRCA1 variants on chr17 (ref='C', alt='T') in gnomAD v2.1.1
SELECT DISTINCT start_position
FROM (
  -- Genomes
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS alt_struct,
       UNNEST(vep)             AS vep_struct
  WHERE vep_struct.SYMBOL      = 'BRCA1'
    AND vep_struct.Consequence LIKE '%missense_variant%'
    AND reference_bases        = 'C'
    AND alt_struct.alt         = 'T'

  UNION DISTINCT

  -- Exomes
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS alt_struct,
       UNNEST(vep)             AS vep_struct
  WHERE vep_struct.SYMBOL      = 'BRCA1'
    AND vep_struct.Consequence LIKE '%missense_variant%'
    AND reference_bases        = 'C'
    AND alt_struct.alt         = 'T'
)
ORDER BY start_position;