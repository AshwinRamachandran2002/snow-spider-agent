-- Smallest BRCA1‐missense amino-acid position in gnomAD v2.1.1 genomes (chr17)
WITH brca1_bounds AS (
  /* 1) Locate genomic span covered by any variant annotated with SYMBOL = 'BRCA1' */
  SELECT
    MIN(start_position) AS region_start,
    MAX(end_position)   AS region_end
  FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17`,
       UNNEST(alternate_bases) AS ab,
       UNNEST(ab.vep)          AS v
  WHERE v.SYMBOL = 'BRCA1'
)

SELECT
  /* 2) Take the part of Protein_position before “/” and cast to INT */
  SAFE_CAST( SPLIT(v.Protein_position, '/')[OFFSET(0)] AS INT64 ) AS first_missense_protein_pos
FROM `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` g,
     UNNEST(g.alternate_bases) AS ab,
     UNNEST(ab.vep)            AS v,
     brca1_bounds b            -- cross-join to gain access to region limits
WHERE g.start_position BETWEEN b.region_start AND b.region_end   -- within BRCA1 span
  AND LOWER(v.Consequence) LIKE '%missense_variant%'              -- missense only
  AND v.Protein_position IS NOT NULL
ORDER BY first_missense_protein_pos
LIMIT 1;