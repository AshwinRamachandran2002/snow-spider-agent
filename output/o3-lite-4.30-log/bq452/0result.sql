WITH sample_groups AS (
  SELECT
    Sample AS id,
    CASE WHEN Super_Population = 'EAS' THEN 'EAS' ELSE 'OTHER' END AS grp
  FROM `genomics-public-data.1000_genomes.sample_info`
),
allele_counts AS (
  SELECT
    v.start,
    v.`end`,
    sg.grp,
    SUM(CASE WHEN g = 0 THEN 1 ELSE 0 END) AS ref_alleles,
    SUM(CASE WHEN g = 1 THEN 1 ELSE 0 END) AS alt_alleles
  FROM `genomics-public-data.1000_genomes.variants` AS v
  JOIN UNNEST(v.call)     AS c
  JOIN UNNEST(c.genotype) AS g
  JOIN sample_groups      AS sg
    ON sg.id = c.call_set_name
  WHERE v.reference_name = '12'
    AND g IN (0, 1)                  -- ignore missing / multi‑allelic genotypes
  GROUP BY v.start, v.`end`, sg.grp
),
four_cells AS (
  SELECT
    start,
    `end`,
    SUM(IF(grp = 'EAS',   ref_alleles, 0)) AS A,  -- ref alleles in cases
    SUM(IF(grp = 'EAS',   alt_alleles, 0)) AS B,  -- alt alleles in cases
    SUM(IF(grp = 'OTHER', ref_alleles, 0)) AS C,  -- ref alleles in controls
    SUM(IF(grp = 'OTHER', alt_alleles, 0)) AS D   -- alt alleles in controls
  FROM allele_counts
  GROUP BY start, `end`
),
expected AS (
  SELECT
    start,
    `end`,
    A, B, C, D,
    (A + B + C + D) AS N,
    (A + C)         AS row_ref,
    (B + D)         AS row_alt,
    (A + B)         AS col_cases,
    (C + D)         AS col_ctrls
  FROM four_cells
),
chi_calc AS (
  SELECT
    start,
    `end`,
    (col_cases * row_ref) / N AS EA,
    (col_cases * row_alt) / N AS EB,
    (col_ctrls * row_ref) / N AS EC,
    (col_ctrls * row_alt) / N AS ED,
    A, B, C, D
  FROM expected
),
chi_squared AS (
  SELECT
    start,
    `end`,
    POWER(ABS(A - EA) - 0.5, 2) / EA +
    POWER(ABS(B - EB) - 0.5, 2) / EB +
    POWER(ABS(C - EC) - 0.5, 2) / EC +
    POWER(ABS(D - ED) - 0.5, 2) / ED AS chi_sq
  FROM chi_calc
  WHERE EA >= 5 AND EB >= 5 AND EC >= 5 AND ED >= 5
)
SELECT
  start       AS start_position,
  `end`       AS end_position,
  ROUND(chi_sq, 4) AS chi_squared
FROM chi_squared
WHERE chi_sq >= 29.71679
ORDER BY chi_squared DESC, start_position, end_position
LIMIT 100;