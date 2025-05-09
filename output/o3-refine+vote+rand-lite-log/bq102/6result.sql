WITH brca1_variants AS (
  -- exomes
  SELECT DISTINCT
    start_position
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
    UNNEST(alternate_bases) AS alt,
    UNNEST(vep)             AS v
  WHERE
    reference_bases = 'C'
    AND alt.alt = 'T'
    AND v.allele = 'T'
    AND v.SYMBOL = 'BRCA1'
    AND v.Consequence LIKE '%missense_variant%'

  UNION DISTINCT

  -- genomes
  SELECT DISTINCT
    start_position
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
    UNNEST(alternate_bases) AS alt,
    UNNEST(vep)             AS v
  WHERE
    reference_bases = 'C'
    AND alt.alt = 'T'
    AND v.allele = 'T'
    AND v.SYMBOL = 'BRCA1'
    AND v.Consequence LIKE '%missense_variant%'
)

SELECT
  start_position
FROM
  brca1_variants
ORDER BY
  start_position;