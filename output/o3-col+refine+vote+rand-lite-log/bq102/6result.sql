/*  Distinct start positions of C→T missense variants in BRCA1 (chr17)
    across both genomes & exomes from gnomAD v2.1.1                         */
SELECT DISTINCT start_position
FROM (
  -- genomes
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL            = 'BRCA1'
    AND LOWER(v.Consequence) LIKE '%missense_variant%'
    AND reference_bases      = 'C'
    AND ab.alt               = 'T'

  UNION DISTINCT

  -- exomes
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL            = 'BRCA1'
    AND LOWER(v.Consequence) LIKE '%missense_variant%'
    AND reference_bases      = 'C'
    AND ab.alt               = 'T'
)
ORDER BY start_position;