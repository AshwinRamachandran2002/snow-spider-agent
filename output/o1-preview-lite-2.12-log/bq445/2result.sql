WITH brca1_region AS (
  SELECT
    MIN(t.start_position) AS min_start,
    MAX(t.end_position) AS max_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
  CROSS JOIN
    UNNEST(t.alternate_bases) AS alt
  CROSS JOIN
    UNNEST(alt.vep) AS vep
  WHERE
    vep.SYMBOL = 'BRCA1'
)
SELECT
  vep.Protein_position
FROM
  `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
CROSS JOIN
  brca1_region
CROSS JOIN
  UNNEST(t.alternate_bases) AS alt
CROSS JOIN
  UNNEST(alt.vep) AS vep
WHERE
  t.start_position BETWEEN brca1_region.min_start AND brca1_region.max_end
  AND vep.Consequence LIKE '%missense_variant%'
ORDER BY
  CAST(REGEXP_EXTRACT(vep.Protein_position, r'^\d+') AS INT64) ASC
LIMIT 1;