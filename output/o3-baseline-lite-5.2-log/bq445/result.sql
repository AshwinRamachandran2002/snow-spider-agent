WITH gene_region AS (
  SELECT
    MIN(start_position) AS gene_start,
    MAX(end_position) AS gene_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
    CROSS JOIN UNNEST(t.alternate_bases) AS alt
    CROSS JOIN UNNEST(alt.vep)           AS vep
  WHERE
    vep.SYMBOL = 'BRCA1'
)

SELECT
  vep.Protein_position
FROM
  `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN gene_region
  CROSS JOIN UNNEST(t.alternate_bases) AS alt
  CROSS JOIN UNNEST(alt.vep)           AS vep
WHERE
  t.start_position BETWEEN gene_start AND gene_end
  AND vep.Consequence LIKE '%missense_variant%'
  AND vep.Protein_position IS NOT NULL
ORDER BY
  SAFE_CAST(REGEXP_EXTRACT(vep.Protein_position, r'^(\d+)') AS INT64)
LIMIT 1;