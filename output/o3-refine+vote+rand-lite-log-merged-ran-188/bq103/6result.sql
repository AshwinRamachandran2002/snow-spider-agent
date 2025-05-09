-- Summary statistics for gnomAD-v3 variants in chr1:55 039 447-55 064 852
WITH
  limits AS (SELECT 55039447 AS bp_start, 55064852 AS bp_end),
  region AS (SELECT bp_end - bp_start + 1 AS region_length FROM limits),

  /* 1. rows (= “sites”); no UNNEST so multi-allelic sites counted once        */
  variants AS (
    SELECT start_position
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1`, limits
    WHERE reference_name = 'chr1'
      AND start_position BETWEEN bp_start AND bp_end
  ),

  /* 2. per-allele metrics; UNNEST alternate_bases to reach AC_raw & n_alts    */
  alleles AS (
    SELECT ab.AC_raw , ab.n_alt_alleles
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` t
    JOIN limits ON TRUE
    CROSS JOIN UNNEST(t.alternate_bases) AS ab
    WHERE t.reference_name = 'chr1'
      AND t.start_position BETWEEN bp_start AND bp_end
  ),

  /* 3. gene symbols (VEP annotation)                                           */
  genes AS (
    SELECT DISTINCT v.SYMBOL
    FROM `bigquery-public-data.gnomAD.v3_genomes__chr1` t
    JOIN limits ON TRUE
    CROSS JOIN UNNEST(t.alternate_bases) AS ab
    CROSS JOIN UNNEST(ab.vep)           AS v
    WHERE t.reference_name = 'chr1'
      AND t.start_position BETWEEN bp_start AND bp_end
      AND v.SYMBOL IS NOT NULL
  )

SELECT
  (SELECT COUNT(*)               FROM variants)                        AS num_variants,
  (SELECT SUM(AC_raw)            FROM alleles)                         AS total_allele_count,
  (SELECT SUM(n_alt_alleles)     FROM alleles)                         AS total_number_of_alt_alleles,
  (SELECT region_length          FROM region)                          AS region_length_bp,
  ROUND(
    (SELECT region_length FROM region) /
    NULLIF((SELECT COUNT(*) FROM variants), 0) , 2)                    AS bp_per_variant,
  (SELECT STRING_AGG(SYMBOL, ',' ORDER BY SYMBOL) FROM genes)          AS genes_in_interval;