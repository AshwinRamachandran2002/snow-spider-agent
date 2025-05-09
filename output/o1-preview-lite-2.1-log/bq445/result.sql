WITH brca1_region AS (
  SELECT
    MIN(start_position) AS brca1_gene_start,
    MAX(end_position) AS brca1_gene_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS t1,
       UNNEST(t1.alternate_bases) AS alt1,
       UNNEST(alt1.vep) AS vep1
  WHERE
    reference_name = '17' AND LOWER(vep1.SYMBOL) = 'brca1'
),
missense_variants AS (
  SELECT
    CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64) AS Protein_Position,
    CONCAT(CAST(start_position AS STRING), '_', alt.alt) AS Variant_ID,
    'missense_variant' AS Consequence,
    brca1_region.brca1_gene_start,
    brca1_region.brca1_gene_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS t,
       UNNEST(t.alternate_bases) AS alt,
       UNNEST(alt.vep) AS vep,
       brca1_region
  WHERE
    reference_name = '17' AND LOWER(vep.SYMBOL) = 'brca1'
    AND start_position BETWEEN brca1_region.brca1_gene_start AND brca1_region.brca1_gene_end
    AND 'missense_variant' IN UNNEST(SPLIT(vep.Consequence, '&'))
)
SELECT
  brca1_gene_start,
  brca1_gene_end,
  Protein_Position,
  Variant_ID,
  Consequence
FROM missense_variants
ORDER BY Protein_Position
LIMIT 10;