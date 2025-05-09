--  Pearson correlation (with p-values) between per-chromosome
--  copy-number-aberration frequencies observed in the Mitelman DB
--  (breast-cancer cases: Morph = 3111, Topo = 0401) and the
--  corresponding frequencies in TCGA (approximated here by the
--  aggregated counts stored in RecurrentNumData).
--
--  Results are shown for each aberration type (Gain and Loss)
--  provided at least five chromosomes have data in common.

WITH
/*------------------------------------------------------------------*/
/* 1)  Mitelman: per-chromosome counts of Gain / Loss events        */
/*------------------------------------------------------------------*/
mitelman AS (
  SELECT
      cc.Chr                                  AS chromosome,          --   e.g.  'chr14'
      cc.Type                                 AS aberration_type,     --   'Gain' | 'Loss'
      COUNT(*)                                AS mitelman_events
  FROM   `mitelman-db.prod.CytoConverted` AS cc
  JOIN   `mitelman-db.prod.Cytogen`       AS cg
         ON  cg.RefNo  = cc.RefNo
         AND cg.CaseNo = cc.CaseNo
  WHERE  cg.Morph = '3111'       -- breast carcinoma
    AND  cg.Topo  = '0401'       -- mammary gland
    AND  cc.Type  IN ('Gain','Loss')
  GROUP  BY chromosome, aberration_type
),

/*------------------------------------------------------------------*/
/* 2)  TCGA proxy: per-chromosome counts from RecurrentNumData      */
/*     (‘+x’ = Gain, ‘-x’ = Loss)                                   */
/*------------------------------------------------------------------*/
tcga AS (
  SELECT
      CONCAT('chr', Chromosome)                           AS chromosome,      -- to match Mitelman
      CASE
        WHEN STARTS_WITH(Abnormality, '+') THEN 'Gain'
        WHEN STARTS_WITH(Abnormality, '-') THEN 'Loss'
      END                                                 AS aberration_type,
      SUM(CAST(TotalCases AS INT64))                      AS tcga_cases
  FROM  `mitelman-db.prod.RecurrentNumData`
  WHERE Morph = '3111'
    AND Topo  = '0401'
    AND (Abnormality LIKE '+%' OR Abnormality LIKE '-%')
  GROUP BY chromosome, aberration_type
),

/*------------------------------------------------------------------*/
/* 3)  Join the two sources on chromosome & aberration type         */
/*------------------------------------------------------------------*/
joined AS (
  SELECT
      m.chromosome,
      m.aberration_type,
      m.mitelman_events,
      t.tcga_cases
  FROM   mitelman AS m
  JOIN   tcga     AS t
    ON   m.chromosome       = t.chromosome
    AND  m.aberration_type  = t.aberration_type
)

/*------------------------------------------------------------------*/
/* 4)  Correlation & p-value (only if ≥5 chromosomes overlap)       */
/*------------------------------------------------------------------*/
SELECT
    aberration_type,
    COUNT(*)                                           AS n_chromosomes,
    CORR(mitelman_events, tcga_cases)                  AS pearson_r,
    `isb-cgc-bq.functions.corr_pvalue_current`
        (CORR(mitelman_events, tcga_cases),
         COUNT(*))                                     AS p_value
FROM   joined
GROUP  BY aberration_type
HAVING COUNT(*) >= 5   -- ensure sufficient data
ORDER  BY aberration_type;