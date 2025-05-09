-- Start positions of C→T missense variants in BRCA1 (chromosome 17) 
-- across gnomAD v2.1.1 exomes and genomes
SELECT DISTINCT start_position
FROM (
  -- v2.1.1 EXOMES
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep
  WHERE vep.SYMBOL = 'BRCA1'
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
    AND reference_bases = 'C'
    AND alt.alt = 'T'

  UNION DISTINCT

  -- v2.1.1 GENOMES
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep
  WHERE vep.SYMBOL = 'BRCA1'
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
    AND reference_bases = 'C'
    AND alt.alt = 'T'
)
ORDER BY start_position;