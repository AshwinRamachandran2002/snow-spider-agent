WITH gene_region AS (
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position) AS max_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
    UNNEST(`alternate_bases`) AS alt_bases,
    UNNEST(alt_bases.vep) AS vep_annotation
  WHERE
    vep_annotation.SYMBOL = 'BRCA1'
)
SELECT
  DISTINCT vep_annotation.Protein_position
FROM
  `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
  gene_region,
  UNNEST(`alternate_bases`) AS alt_bases,
  UNNEST(alt_bases.vep) AS vep_annotation
WHERE
  start_position BETWEEN gene_region.min_start AND gene_region.max_end
  AND vep_annotation.Consequence LIKE '%missense_variant%'
ORDER BY
  CAST(REGEXP_EXTRACT(vep_annotation.Protein_position, r'^\d+') AS INT64) ASC
LIMIT
  1;