-- start positions of C>T missense variants in BRCA1 on chr17 (gnomAD v2.1.1)
WITH hits AS (
  -- exomes
  SELECT DISTINCT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(vep)            AS v
  WHERE reference_bases = 'C'
    AND ab.alt = 'T'          -- C > T change
    AND v.allele = 'T'        -- match same allele in VEP annotation
    AND UPPER(v.SYMBOL) = 'BRCA1'
    AND v.Consequence LIKE '%missense_variant%'
  
  UNION DISTINCT
  
  -- genomes
  SELECT DISTINCT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(vep)            AS v
  WHERE reference_bases = 'C'
    AND ab.alt = 'T'
    AND v.allele = 'T'
    AND UPPER(v.SYMBOL) = 'BRCA1'
    AND v.Consequence LIKE '%missense_variant%'
)

SELECT start_position
FROM hits
ORDER BY start_position;