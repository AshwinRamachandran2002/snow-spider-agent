-- Same analysis, but using the public 1000 Genomes dataset that is
-- guaranteed to be accessible: `genomics-public-data.1000_genomes.*`
WITH allele_counts AS (
  SELECT
    v.start,
    v.`end`,
    -- observed allele counts in the two groups
    SUM(
      CASE WHEN s.Super_Population = 'EAS'
           THEN (SELECT COUNTIF(g = 0) FROM UNNEST(c.genotype) AS g) END
    ) AS ref_eas,
    SUM(
      CASE WHEN s.Super_Population = 'EAS'
           THEN (SELECT COUNTIF(g = 1) FROM UNNEST(c.genotype) AS g) END
    ) AS alt_eas,
    SUM(
      CASE WHEN s.Super_Population <> 'EAS'
           THEN (SELECT COUNTIF(g = 0) FROM UNNEST(c.genotype) AS g) END
    ) AS ref_non_eas,
    SUM(
      CASE WHEN s.Super_Population <> 'EAS'
           THEN (SELECT COUNTIF(g = 1) FROM UNNEST(c.genotype) AS g) END
    ) AS alt_non_eas
  FROM `genomics-public-data.1000_genomes.variants`            AS v
  JOIN UNNEST(v.call)                                          AS c
  LEFT JOIN `genomics-public-data.1000_genomes.sample_info`    AS s
         ON s.Sample = c.call_set_name
  WHERE v.reference_name = '12'
  GROUP BY v.start, v.`end`
),
stats AS (
  SELECT
    *,
    (alt_eas + ref_eas)                         AS cases_total,
    (alt_non_eas + ref_non_eas)                 AS ctrls_total,
    (alt_eas + alt_non_eas)                     AS alt_total,
    (ref_eas + ref_non_eas)                     AS ref_total,
    (alt_eas + ref_eas + alt_non_eas + ref_non_eas) AS grand_total
  FROM allele_counts
),
expected_ok AS (
  SELECT
    *,
    -- expected counts for each of the four cells
    cases_total  * alt_total  / grand_total AS exp_alt_eas,
    cases_total  * ref_total  / grand_total AS exp_ref_eas,
    ctrls_total  * alt_total  / grand_total AS exp_alt_ctrl,
    ctrls_total  * ref_total  / grand_total AS exp_ref_ctrl
  FROM stats
  WHERE grand_total  > 0
    AND cases_total  > 0
    AND ctrls_total  > 0
    -- all four expected counts must be at least 5
    AND cases_total  * alt_total  / grand_total >= 5
    AND cases_total  * ref_total  / grand_total >= 5
    AND ctrls_total  * alt_total  / grand_total >= 5
    AND ctrls_total  * ref_total  / grand_total >= 5
),
chi2 AS (
  SELECT
    start,
    `end`,
    -- Yates-corrected χ² for a 2×2 table:
    -- χ² = N * (|ad − bc| − N/2)² / (R1 * R2 * C1 * C2)
    grand_total *
    POW(ABS(alt_eas * ref_non_eas - ref_eas * alt_non_eas) - 0.5 * grand_total, 2) /
    (cases_total * ctrls_total * alt_total * ref_total) AS chi_squared
  FROM expected_ok
)
SELECT
  start,
  `end`,
  chi_squared
FROM chi2
WHERE chi_squared >= 29.71679
ORDER BY chi_squared DESC