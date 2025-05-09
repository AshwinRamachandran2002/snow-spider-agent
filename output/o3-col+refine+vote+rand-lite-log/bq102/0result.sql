-- Distinct genomic coordinates of C→T missense variants in BRCA1 on chr17
SELECT DISTINCT start_position
FROM (
  -- gnomAD v2.1.1 genomes, chromosome 17
  SELECT g.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g,
       UNNEST(g.alternate_bases) AS alt,
       UNNEST(alt.vep)          AS v
  WHERE g.reference_bases = 'C'          -- reference base
    AND alt.alt            = 'T'         -- alternate base
    AND v.SYMBOL           = 'BRCA1'     -- gene filter
    AND v.Consequence LIKE '%missense_variant%'
  
  UNION ALL
  
  -- gnomAD v2.1.1 exomes, chromosome 17
  SELECT e.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS e,
       UNNEST(e.alternate_bases) AS alt,
       UNNEST(alt.vep)          AS v
  WHERE e.reference_bases = 'C'
    AND alt.alt            = 'T'
    AND v.SYMBOL           = 'BRCA1'
    AND v.Consequence LIKE '%missense_variant%'
)
ORDER BY start_position;