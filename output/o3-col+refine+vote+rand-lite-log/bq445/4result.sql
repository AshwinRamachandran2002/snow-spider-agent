WITH brca_region AS (
  -- Determine the genomic span of BRCA1 based on any variant annotated with SYMBOL = 'BRCA1'
  SELECT
    MIN(start_position) AS min_start,
    MAX(end_position)   AS max_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` g,
       UNNEST(g.alternate_bases) AS alt,
       UNNEST(alt.vep)           AS vep
  WHERE vep.SYMBOL = 'BRCA1'
)

-- Within that span, find missense variants and return the smallest protein position
SELECT
  SAFE_CAST(SPLIT(vep.Protein_position, '/')[OFFSET(0)] AS INT64) AS first_protein_position
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` g,
     UNNEST(g.alternate_bases) AS alt,
     UNNEST(alt.vep)           AS vep,
     brca_region r
WHERE g.start_position >= r.min_start
  AND g.end_position   <= r.max_end
  AND LOWER(vep.Consequence) LIKE '%missense_variant%'
  AND vep.Protein_position IS NOT NULL
ORDER BY first_protein_position
LIMIT 1;