SELECT DISTINCT t.start_position
FROM `bigquery-public-data.gnomAD.v2_1_1_exomes__chr17` AS t
JOIN UNNEST(t.alternate_bases) AS alt_bases
WHERE t.reference_bases = 'C'
  AND alt_bases.alt = 'T'
  AND t.start_position BETWEEN 41197695 AND 41276113