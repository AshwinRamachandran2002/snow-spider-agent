WITH brca1_region AS (         -- genomic span covered by any BRCA1‑annotated variant
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN
    UNNEST(t.alternate_bases) AS ab
  CROSS JOIN
    UNNEST(ab.vep) AS v
  WHERE
    v.SYMBOL = 'BRCA1'
),
missense_proteins AS (         -- missense Protein_position values inside that span
  SELECT
    v.Protein_position AS protein_pos
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS t
  CROSS JOIN
    UNNEST(t.alternate_bases) AS ab
  CROSS JOIN
    UNNEST(ab.vep) AS v
  CROSS JOIN
    brca1_region AS r
  WHERE
        t.start_position BETWEEN r.min_start AND r.max_end
    AND LOWER(v.Consequence) LIKE '%missense_variant%'
    AND v.Protein_position IS NOT NULL
)
SELECT                           -- first (smallest) Protein_position
  protein_pos AS Protein_position
FROM
  missense_proteins
ORDER BY
  SAFE_CAST(REGEXP_EXTRACT(protein_pos, r'^\d+') AS INT64)
LIMIT 1;