WITH per_allele AS (
  -- One row per allele (0 = reference, >0 = alternate) for every sample on chr 12
  SELECT
    v.start,
    v.end,
    CASE
      WHEN s.super_population = 'EAS' THEN 'CASE'
      ELSE 'CONTROL'
    END                                   AS grp,
    CASE WHEN g = 0 THEN 1 ELSE 0 END    AS is_ref,
    CASE WHEN g > 0 THEN 1 ELSE 0 END    AS is_alt
  FROM `genomics-public-data.1000_genomes.variants`      AS v
  CROSS JOIN UNNEST(v.call)                              AS c
  JOIN `genomics-public-data.1000_genomes.sample_info`   AS s
    ON s.sample = c.call_set_name
  CROSS JOIN UNNEST(c.genotype)                          AS g      -- each allele
  WHERE v.reference_name = '12'
    AND g >= 0                                           -- ignore missing (-1)
),
allele_sums AS (
  -- Totals per variant and group (CASE / CONTROL)
  SELECT
    start,
    `end`,
    grp,
    SUM(is_alt) AS alt_alleles,
    SUM(is_ref) AS ref_alleles
  FROM per_allele
  GROUP BY start, `end`, grp
),
counts AS (
  -- 2×2 table counts for χ²
  SELECT
    start,
    `end`,
    SUM(IF(grp = 'CASE',    alt_alleles, 0)) AS A,
    SUM(IF(grp = 'CASE',    ref_alleles, 0)) AS B,
    SUM(IF(grp = 'CONTROL', alt_alleles, 0)) AS C,
    SUM(IF(grp = 'CONTROL', ref_alleles, 0)) AS D
  FROM allele_sums
  GROUP BY start, `end`
),
stats AS (
  -- Totals and expected counts
  SELECT
    start,
    `end`,
    A, B, C, D,
    (A + B)                 AS case_total,
    (C + D)                 AS ctrl_total,
    (A + C)                 AS alt_total,
    (B + D)                 AS ref_total,
    (A + B + C + D)         AS N
  FROM counts
),
filtered AS (
  -- Expected counts and Yates‑corrected χ²
  SELECT
    start,
    `end`,
    (alt_total * case_total)  / N AS exp_A,
    (alt_total * ctrl_total)  / N AS exp_C,
    (ref_total * case_total)  / N AS exp_B,
    (ref_total * ctrl_total)  / N AS exp_D,
    ( N * POW(ABS(A * D - B * C) - 0.5 * N, 2)
        / ( (A + B) * (C + D) * (A + C) * (B + D) )
    ) AS chi_sq
  FROM stats
  WHERE N > 0
)
SELECT
  start AS start_position,
  `end` AS end_position,
  ROUND(chi_sq, 4) AS chi_squared
FROM filtered
WHERE exp_A >= 5
  AND exp_B >= 5
  AND exp_C >= 5
  AND exp_D >= 5
  AND chi_sq >= 29.71679
ORDER BY chi_squared DESC, start_position;