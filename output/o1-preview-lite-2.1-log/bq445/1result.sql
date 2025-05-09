SELECT
  CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64) AS Protein_Position,
  CONCAT(CAST(start_position AS STRING), '_', reference_bases, '/', alternate_bases.alt) AS Variant_ID,
  vep.Consequence
FROM
  `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
  UNNEST(alternate_bases) AS alternate_bases,
  UNNEST(alternate_bases.vep) AS vep
WHERE
  start_position BETWEEN 41196311 AND 41322420
  AND vep.SYMBOL = 'BRCA1'
  AND vep.Consequence LIKE '%missense_variant%'
  AND alternate_bases.alt = vep.Allele
ORDER BY
  CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64)
LIMIT 10;