/*  SNP genotype profile on chromosome X outside pseudo‑autosomal regions  */

WITH selected_calls AS (
  -- 1. Select SNPs on chr‑X, outside both PAR regions,
  --    keeping only calls that contain at least one allele.
  SELECT
    c.call_set_name AS sample_id,
    c.genotype      AS g
  FROM `genomics-public-data.1000_genomes.variants` AS v
  CROSS JOIN UNNEST(v.call) AS c
  WHERE v.reference_name = 'X'
        -- single‑nucleotide variants only
        AND LENGTH(v.reference_bases) = 1
        AND ARRAY_LENGTH(v.alternate_bases) = 1
        AND LENGTH(v.alternate_bases[OFFSET(0)]) = 1
        -- exclude pseudo‑autosomal regions on chr‑X
        AND NOT (v.start BETWEEN   59999     AND   2699519)
        AND NOT (v.start BETWEEN 154931042   AND 155260559)
        -- at least one allele recorded
        AND ARRAY_LENGTH(c.genotype) > 0
),
categorized AS (
  -- 2. Classify each genotype call
  SELECT
    sample_id,

    -- homozygous reference (0/0)
    IF(ARRAY_LENGTH(g) = 2
       AND g[OFFSET(0)] = 0
       AND g[OFFSET(1)] = 0, 1, 0)                              AS hom_ref,

    -- homozygous alternate (e.g., 1/1, 2/2)
    IF(ARRAY_LENGTH(g) = 2
       AND g[OFFSET(0)] > 0
       AND g[OFFSET(0)] = g[OFFSET(1)], 1, 0)                   AS hom_alt,

    -- heterozygous (contains ≥1 alternate allele, not hom_ref or hom_alt)
    CASE
      WHEN (SELECT COUNTIF(a > 0) FROM UNNEST(g) AS a) > 0
           AND NOT (ARRAY_LENGTH(g) = 2 AND g[OFFSET(0)] = 0 AND g[OFFSET(1)] = 0)
           AND NOT (ARRAY_LENGTH(g) = 2 AND g[OFFSET(0)] > 0 AND g[OFFSET(0)] = g[OFFSET(1)])
      THEN 1 ELSE 0
    END                                                         AS het
  FROM selected_calls
)

-- 3. Aggregate counts per sample and compute requested metrics
SELECT
  sample_id                                                       AS sample,
  SUM(hom_ref) + SUM(hom_alt) + SUM(het)                          AS total_callable_sites,
  SUM(hom_ref)                                                    AS homozygous_reference,
  SUM(hom_alt)                                                    AS homozygous_alternate,
  SUM(het)                                                        AS heterozygous,
  SUM(hom_alt) + SUM(het)                                         AS total_snvs,
  ROUND(
    SAFE_DIVIDE(SUM(het) * 100.0, NULLIF(SUM(hom_alt) + SUM(het), 0)),
    4
  )                                                               AS heterozygous_pct_of_snvs,
  ROUND(
    SAFE_DIVIDE(SUM(hom_alt) * 100.0, NULLIF(SUM(hom_alt) + SUM(het), 0)),
    4
  )                                                               AS homozygous_alt_pct_of_snvs
FROM categorized
GROUP BY sample
ORDER BY heterozygous_pct_of_snvs DESC, sample;