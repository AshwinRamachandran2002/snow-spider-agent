-- missense C>T BRCA1 variants on chr17 (gnomAD v2.1.1 genomes + exomes)
WITH positions AS (
  -- Genomes
  SELECT DISTINCT g.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g,
       UNNEST(g.alternate_bases) AS alt,
       UNNEST(alt.vep)           AS vep
  WHERE g.reference_bases = 'C'
    AND alt.alt            = 'T'
    AND vep.SYMBOL         = 'BRCA1'
    AND vep.Consequence    LIKE '%missense_variant%'

  UNION DISTINCT

  -- Exomes
  SELECT DISTINCT e.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS e,
       UNNEST(e.alternate_bases) AS alt,
       UNNEST(alt.vep)           AS vep
  WHERE e.reference_bases = 'C'
    AND alt.alt            = 'T'
    AND vep.SYMBOL         = 'BRCA1'
    AND vep.Consequence    LIKE '%missense_variant%'
)

SELECT start_position
FROM   positions
ORDER  BY start_position;