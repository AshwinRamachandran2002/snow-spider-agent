-- Missense C>T variants in BRCA1 on chromosome 17 (gnomAD v2.1.1 GENOMES + EXOMES)
WITH brca1_ct_missense AS (
  -- GENOMES
  SELECT g.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g,
       UNNEST(g.alternate_bases) AS ab,
       UNNEST(ab.vep)            AS v
  WHERE g.reference_bases = 'C'           -- reference base
    AND ab.alt            = 'T'           -- alternate base
    AND v.SYMBOL          = 'BRCA1'       -- gene
    AND LOWER(v.Consequence) LIKE '%missense_variant%'   -- consequence
  
  UNION DISTINCT
  
  -- EXOMES
  SELECT e.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS e,
       UNNEST(e.alternate_bases) AS ab,
       UNNEST(ab.vep)            AS v
  WHERE e.reference_bases = 'C'
    AND ab.alt            = 'T'
    AND v.SYMBOL          = 'BRCA1'
    AND LOWER(v.Consequence) LIKE '%missense_variant%'
)

SELECT DISTINCT start_position
FROM brca1_ct_missense
ORDER BY start_position;