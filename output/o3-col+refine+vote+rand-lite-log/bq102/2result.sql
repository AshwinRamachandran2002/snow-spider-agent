-- Missense C>T variants in BRCA1 on chr17 (gnomAD v2.1.1; genomes + exomes)
WITH brca1_missense AS (
  ------------------------------------------------------------------
  -- Genomes call-set
  ------------------------------------------------------------------
  SELECT g.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g
  CROSS JOIN UNNEST(g.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)          AS vep
  WHERE g.reference_bases = 'C'          -- reference is C
    AND alt.alt          = 'T'           -- alternate is T
    AND vep.SYMBOL       = 'BRCA1'       -- gene symbol
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'   -- missense
  
  UNION DISTINCT
  
  ------------------------------------------------------------------
  -- Exomes call-set
  ------------------------------------------------------------------
  SELECT e.start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS e
  CROSS JOIN UNNEST(e.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS vep
  WHERE e.reference_bases = 'C'
    AND alt.alt          = 'T'
    AND vep.SYMBOL       = 'BRCA1'
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
)

SELECT DISTINCT start_position
FROM brca1_missense
ORDER BY start_position;