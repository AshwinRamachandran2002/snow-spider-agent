-- Missense C>T BRCA1 variants on chr17 (gnomAD v2.1.1 – genomes + exomes)
WITH brca1_missense AS (
  -- Genomes
  SELECT start_position
  FROM  `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
        UNNEST(alternate_bases) AS ab,
        UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL               = 'BRCA1'
    AND LOWER(v.Consequence)  LIKE '%missense_variant%'
    AND reference_bases        = 'C'
    AND ab.alt                 = 'T'

  UNION DISTINCT

  -- Exomes
  SELECT start_position
  FROM  `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
        UNNEST(alternate_bases) AS ab,
        UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL               = 'BRCA1'
    AND LOWER(v.Consequence)  LIKE '%missense_variant%'
    AND reference_bases        = 'C'
    AND ab.alt                 = 'T'
)

SELECT DISTINCT start_position
FROM   brca1_missense
ORDER  BY start_position;