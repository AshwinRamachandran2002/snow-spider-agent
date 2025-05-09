-- Smallest BRCA1 missense Protein_position within its genomic span on chr17 (gnomAD v2.1.1 genomes)
WITH brca1_region AS (
  -- Locate genomic span covered by any variant that has a VEP SYMBOL = 'BRCA1'
  SELECT
    MIN(v.start_position) AS region_start,
    MAX(v.end_position)   AS region_end
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS v
    CROSS JOIN UNNEST(v.alternate_bases) AS alt
    CROSS JOIN UNNEST(alt.vep) AS vep
  WHERE
    vep.SYMBOL = 'BRCA1'
),
missense_proteins AS (
  -- Within that region collect Protein_position values whose consequence includes 'missense_variant'
  SELECT
    vep.Protein_position                          AS protein_position,
    SAFE_CAST(REGEXP_EXTRACT(vep.Protein_position,
                              r'^(\d+)') AS INT64) AS pos_start_num
  FROM
    `bigquery-public-data.gnomAD.v2_1_1_genomes__chr17` AS v
    CROSS JOIN UNNEST(v.alternate_bases) AS alt
    CROSS JOIN UNNEST(alt.vep)           AS vep,
    brca1_region r
  WHERE
        v.start_position BETWEEN r.region_start AND r.region_end
    AND vep.Consequence LIKE '%missense_variant%'
    AND vep.Protein_position IS NOT NULL
)
SELECT
  protein_position
FROM
  missense_proteins
ORDER BY
  pos_start_num
LIMIT 1;