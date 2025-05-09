-- BRCA1 missense C>T variant start positions on chromosome 17 (gnomAD v2.1.1 exomes)
SELECT DISTINCT
  start_position
FROM (
  SELECT
    start_position,
    reference_bases,
    alt.alt                          AS alt_allele,
    vep                              -- VEP annotations array
  FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17`
  CROSS JOIN UNNEST(alternate_bases) AS alt            -- explode allele structs
) AS flat
WHERE reference_bases = 'C'               -- reference base C
  AND alt_allele     = 'T'                -- alternate base T (C>T)
  AND EXISTS (                            -- missense annotation in BRCA1
        SELECT 1
        FROM UNNEST(vep) AS v
        WHERE v.allele      = 'T'
          AND v.SYMBOL      = 'BRCA1'
          AND v.Consequence LIKE '%missense_variant%'
      )
ORDER BY start_position;