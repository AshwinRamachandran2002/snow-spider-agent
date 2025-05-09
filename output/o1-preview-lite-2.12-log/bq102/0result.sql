SELECT DISTINCT start_position
FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`,
UNNEST(alternate_bases) AS alt_base,
UNNEST(vep) AS vep_info
WHERE reference_bases = 'C'
  AND alt_base.alt = 'T'
  AND vep_info.SYMBOL = 'BRCA1'
  AND vep_info.Consequence LIKE '%missense_variant%'