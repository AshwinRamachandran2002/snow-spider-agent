/*  C→T missense‑variant start positions in BRCA1 on chr17  (gnomAD v2.1.1)  */
WITH exomes AS (
  SELECT DISTINCT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(vep)             AS vep
  WHERE reference_bases = 'C'
    AND alt.alt        = 'T'
    AND vep.allele     = 'T'
    AND vep.SYMBOL     = 'BRCA1'
    AND vep.Consequence LIKE '%missense_variant%'
),
genomes AS (
  SELECT DISTINCT start_position
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(vep)             AS vep
  WHERE reference_bases = 'C'
    AND alt.alt        = 'T'
    AND vep.allele     = 'T'
    AND vep.SYMBOL     = 'BRCA1'
    AND vep.Consequence LIKE '%missense_variant%'
)

SELECT DISTINCT start_position
FROM   exomes
UNION DISTINCT
SELECT DISTINCT start_position
FROM   genomes
ORDER BY start_position;