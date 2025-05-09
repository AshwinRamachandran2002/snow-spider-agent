-- start positions of C>T missense variants in BRCA1 on chr17 (gnomAD v2.1.1)
SELECT DISTINCT
  start_position
FROM (
  /* exomes */
  SELECT
    start_position
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
    UNNEST(alternate_bases) AS alt,
    UNNEST(alt.vep)        AS vep
  WHERE
        reference_bases = 'C'
    AND alt.alt          = 'T'
    AND vep.SYMBOL       = 'BRCA1'
    AND vep.Consequence  LIKE '%missense_variant%'
  
  UNION DISTINCT
  
  /* genomes */
  SELECT
    start_position
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
    UNNEST(alternate_bases) AS alt,
    UNNEST(alt.vep)        AS vep
  WHERE
        reference_bases = 'C'
    AND alt.alt          = 'T'
    AND vep.SYMBOL       = 'BRCA1'
    AND vep.Consequence  LIKE '%missense_variant%'
)
ORDER BY
  start_position;