WITH brca_region AS (        -- 1. genomic span of any BRCA1‑annotated variant
  SELECT
    MIN(start_position) AS region_start,
    MAX(end_position)   AS region_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN UNNEST(t.alternate_bases)            AS ab
  CROSS JOIN UNNEST(ab.vep)                       AS v
  WHERE
    v.SYMBOL = 'BRCA1'
),
missense_positions AS (      -- 2. missense variants inside that span
  SELECT
    CAST(REGEXP_EXTRACT(v.Protein_position, r'^(\d+)') AS INT64) AS protein_pos_num,
    v.Protein_position AS protein_pos
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN brca_region
  CROSS JOIN UNNEST(t.alternate_bases)            AS ab
  CROSS JOIN UNNEST(ab.vep)                       AS v
  WHERE
        t.start_position >= brca_region.region_start
    AND t.end_position   <= brca_region.region_end
    AND v.Consequence    LIKE '%missense_variant%'
    AND v.Protein_position IS NOT NULL
    AND REGEXP_CONTAINS(v.Protein_position, r'^\d+')          -- keep positions that begin with a number
)
SELECT
  protein_pos
FROM
  missense_positions
ORDER BY
  protein_pos_num
LIMIT 1;