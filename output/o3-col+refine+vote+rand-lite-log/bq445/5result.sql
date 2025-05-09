WITH brca1_span AS (
  -- 1. Genomic span of all BRCA1–annotated variants
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep
  WHERE vep.SYMBOL = 'BRCA1'
),
missense AS (
  -- 2. Missense variants that fall inside that span
  SELECT
    DISTINCT vep.Protein_position AS protein_pos,
    CAST(SPLIT(vep.Protein_position,'/')[SAFE_OFFSET(0)] AS INT64) AS pos_num
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       brca1_span,
       UNNEST(alternate_bases) AS alt,
       UNNEST(alt.vep)         AS vep
  WHERE start_position BETWEEN brca1_span.min_start AND brca1_span.max_end
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
-- 3. First (smallest) Protein_position
SELECT protein_pos AS Protein_position
FROM   missense
ORDER  BY pos_num
LIMIT  1;