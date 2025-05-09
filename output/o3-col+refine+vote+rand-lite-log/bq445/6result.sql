WITH region AS (
  -- 1. Genomic span of all BRCA1–annotated variants
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g,
       UNNEST(g.alternate_bases) AS alt,
       UNNEST(alt.vep)           AS vep
  WHERE vep.SYMBOL = 'BRCA1'
),
ranked AS (
  -- 2. Missense variants that fall inside that span
  SELECT
    vep.Protein_position,
    SAFE_CAST(SPLIT(vep.Protein_position, '/')[SAFE_OFFSET(0)] AS INT64) AS pos_int
  FROM region,
       `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS g,
       UNNEST(g.alternate_bases) AS alt,
       UNNEST(alt.vep)           AS vep
  WHERE g.start_position BETWEEN region.min_start AND region.max_end
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
-- 3. Smallest Protein_position
SELECT Protein_position
FROM ranked
ORDER BY pos_int
LIMIT 1;