SELECT DISTINCT start_position
FROM (
  -- genomes table
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(vep)             AS v
  WHERE reference_name  = '17'
    AND reference_bases = 'C'
    AND ab.alt          = 'T'
    AND v.allele        = 'T'
    AND v.SYMBOL        = 'BRCA1'
    AND v.Consequence   LIKE '%missense_variant%'
  UNION DISTINCT
  -- exomes table
  SELECT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(vep)             AS v
  WHERE reference_name  = '17'
    AND reference_bases = 'C'
    AND ab.alt          = 'T'
    AND v.allele        = 'T'
    AND v.SYMBOL        = 'BRCA1'
    AND v.Consequence   LIKE '%missense_variant%'
)
ORDER BY start_position;