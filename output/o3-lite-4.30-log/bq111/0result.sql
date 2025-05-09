WITH cohort AS (
  -- breast‑cancer cases (Morph = 3111, Topo = 0401) in Mitelman
  SELECT DISTINCT FORMAT('%d-%s', RefNo, CaseNo) AS case_id
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111'
    AND Topo  = '0401'
),
mitelman AS (
  -- number of cases with each CNA category on each chromosome
  SELECT
    REPLACE(cc.Chr, 'chr', '') AS chromosome,
    CASE
      WHEN cc.Type = 'Amp'                      THEN 'Amp'
      WHEN cc.Type = 'Gain'                     THEN 'Gain'
      WHEN cc.Type IN ('Loss','Del','Deletion') THEN 'Loss'
    END                                         AS aberration_type,
    COUNT(DISTINCT FORMAT('%d-%s', cc.RefNo, cc.CaseNo)) AS mitelman_cases
  FROM `mitelman-db.prod.CytoConverted` AS cc
  JOIN `mitelman-db.prod.Cytogen`       AS c
    ON c.RefNo  = cc.RefNo
   AND c.CaseNo = cc.CaseNo
  WHERE c.Morph = '3111'
    AND c.Topo  = '0401'
    AND cc.Type IN ('Amp','Gain','Loss','Del','Deletion')
  GROUP BY chromosome, aberration_type
),
tcga AS (
  -- TCGA‑like counts from RecurrentNumData
  SELECT
    Chromosome AS chromosome,
    CASE
      WHEN Abnormality LIKE '++%' THEN 'Amp'
      WHEN Abnormality LIKE '+%'  THEN 'Gain'
      ELSE 'Loss'
    END                    AS aberration_type,
    CAST(TotalCases AS INT64) AS tcga_cases
  FROM `mitelman-db.prod.RecurrentNumData`
  WHERE Morph = '3111'
    AND Topo  = '0401'
    AND (Abnormality LIKE '+%' OR Abnormality LIKE '-%')
),
joined AS (
  -- chromosomes present in both datasets for the same aberration type
  SELECT
    m.chromosome,
    m.aberration_type,
    m.mitelman_cases,
    t.tcga_cases
  FROM mitelman AS m
  JOIN tcga     AS t
    ON  t.chromosome      = m.chromosome
    AND t.aberration_type = m.aberration_type
),
corr_by_type AS (
  -- Pearson correlation across chromosomes for each aberration type
  SELECT
    aberration_type,
    CORR(mitelman_cases, tcga_cases) AS r_raw,
    COUNT(*)                        AS n_pts
  FROM joined
  GROUP BY aberration_type
  HAVING n_pts >= 5                -- keep only types with ≥5 chromosomes
)
SELECT
  'all'                          AS chromosome,
  aberration_type,
  ROUND(r_raw,   4)              AS pearson_r,
  ROUND(
    `isb-cgc-bq.functions.corr_pvalue_current`(r_raw, n_pts), 4
  )                              AS p_value
FROM corr_by_type
ORDER BY aberration_type;