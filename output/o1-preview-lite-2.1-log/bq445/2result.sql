SELECT
  CAST(REGEXP_EXTRACT(vep_annotation.Protein_position, r'^(\d+)') AS INT64) AS Protein_Position,
  CONCAT('chr17:', CAST(start_position AS STRING), ':', reference_bases, '>', alt_bases.alt) AS Variant_ID,
  vep_annotation.Consequence
FROM
  `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
  UNNEST(alternate_bases) AS alt_bases,
  UNNEST(alt_bases.vep) AS vep_annotation
WHERE
  vep_annotation.SYMBOL = 'BRCA1'
  AND vep_annotation.Consequence = 'missense_variant'
ORDER BY
  CAST(REGEXP_EXTRACT(vep_annotation.Protein_position, r'^(\d+)') AS INT64)
LIMIT 100;