SELECT DISTINCT vep.Protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t,
UNNEST(t.alternate_bases) AS alt_base,
UNNEST(alt_base.vep) AS vep
WHERE t.start_position BETWEEN
    (SELECT MIN(t2.start_position)
     FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t2,
     UNNEST(t2.alternate_bases) AS alt_base2,
     UNNEST(alt_base2.vep) AS vep2
     WHERE vep2.SYMBOL = 'BRCA1')
    AND
    (SELECT MAX(t3.end_position)
     FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t3,
     UNNEST(t3.alternate_bases) AS alt_base3,
     UNNEST(alt_base3.vep) AS vep3
     WHERE vep3.SYMBOL = 'BRCA1')
  AND vep.Consequence LIKE '%missense_variant%'
  AND vep.Protein_position IS NOT NULL
ORDER BY CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64) ASC
LIMIT 1