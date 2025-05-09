-- Summary statistics for gnomAD v3 variants on chr1:55 039 447‑55 064 852
WITH variants AS (
  SELECT *
  FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`
  WHERE reference_name = 'chr1'
    AND start_position BETWEEN 55039447 AND 55064852
),
/* total allele count (sum of AC across every alternate allele) */
ac_tot AS (
  SELECT SUM(ab.AC) AS total_ac
  FROM variants
  CROSS JOIN UNNEST(variants.alternate_bases) AS ab
),
/* collect distinct gene symbols from VEP that live inside alternate_bases */
gene_symbols AS (
  SELECT DISTINCT vep_entry.SYMBOL
  FROM variants
  CROSS JOIN UNNEST(variants.alternate_bases)        AS ab
  CROSS JOIN UNNEST(ab.vep)                          AS vep_entry
  WHERE vep_entry.SYMBOL IS NOT NULL
        AND vep_entry.SYMBOL <> ''
)
SELECT
  COUNT(*)                                            AS num_variants,
  (SELECT total_ac FROM ac_tot)                       AS total_allele_count,
  SUM(AN)                                             AS total_AN,
  (SELECT STRING_AGG(SYMBOL, ', ' ORDER BY SYMBOL)
     FROM gene_symbols)                               AS gene_symbols,
  25406.0 / COUNT(*)                                  AS mutation_density -- region length / variant count
FROM variants;