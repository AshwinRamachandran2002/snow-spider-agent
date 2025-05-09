WITH brca1_region AS (                -- 1) genomic span of BRCA1-annotated variants
  SELECT
    MIN(start_position) AS region_start,
    MAX(end_position)   AS region_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t,
       UNNEST(t.alternate_bases) alt,
       UNNEST(alt.vep) vep
  WHERE vep.SYMBOL = 'BRCA1'
),
missense AS (                         -- 2) missense Protein_position values inside that span
  SELECT DISTINCT
    vep.Protein_position AS protein_pos
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` t
  CROSS JOIN UNNEST(t.alternate_bases) alt
  CROSS JOIN UNNEST(alt.vep) vep
  CROSS JOIN brca1_region r           -- single-row CROSS JOIN supplies region bounds
  WHERE t.start_position BETWEEN r.region_start AND r.region_end
    AND LOWER(vep.Consequence) LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
SELECT                                -- 3) smallest Protein_position (numeric order)
  protein_pos
FROM missense
ORDER BY CAST(SPLIT(protein_pos, '/')[SAFE_ORDINAL(1)] AS INT64)
LIMIT 1;