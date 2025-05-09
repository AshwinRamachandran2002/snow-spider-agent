WITH mitelman AS (
  -- Breast‑cancer (Morph = 3111, Topo = 0401) CNA counts in Mitelman
  SELECT
    conv.Chr  AS chromosome,          -- e.g. 'chr1'
    conv.Type AS aberration_type,     -- Gain / Amp / Loss / Deletion
    COUNT(*)  AS mitelman_ct
  FROM `mitelman-db.prod.Cytogen`       AS cy
  JOIN `mitelman-db.prod.CytoConverted` AS conv
    ON  cy.RefNo  = conv.RefNo
   AND cy.CaseNo = conv.CaseNo
  WHERE cy.Morph = '3111'
    AND cy.Topo  = '0401'
    AND conv.Type IN ('Gain','Amp','Loss','Deletion')
  GROUP BY chromosome, aberration_type
),
tcga AS (
  -- TCGA‑BRCA masked copy‑number segments (hg38) grouped the same way
  SELECT
    CONCAT('chr', chromosome) AS chromosome,        -- harmonise label
    CASE
      WHEN segment_mean >=  1.0  THEN 'Amp'
      WHEN segment_mean >=  0.3  THEN 'Gain'
      WHEN segment_mean <= -1.0  THEN 'Deletion'
      WHEN segment_mean <= -0.3  THEN 'Loss'
    END                           AS aberration_type,
    COUNT(*)                      AS tcga_ct
  FROM `isb-cgc.TCGA_hg38_data_v0.Copy_Number_Segment_Masked`
  WHERE project_short_name = 'TCGA-BRCA'
    AND (segment_mean >= 0.3 OR segment_mean <= -0.3)      -- keep only aberrant segments
  GROUP BY chromosome, aberration_type
  HAVING aberration_type IS NOT NULL
),
joined AS (
  -- Chromosomes present in BOTH data sets for the same aberration type
  SELECT
    m.chromosome,
    m.aberration_type,
    m.mitelman_ct AS x,
    t.tcga_ct     AS y
  FROM mitelman AS m
  JOIN tcga     AS t
    ON  m.chromosome      = t.chromosome
   AND m.aberration_type  = t.aberration_type
)
-- Compute Pearson correlation by aberration type (require ≥5 chromosomes)
SELECT
  aberration_type,
  ROUND(CORR(x, y), 4) AS pearson_r,
  ROUND(`isb-cgc-bq.functions.corr_pvalue_current`(CORR(x, y), COUNT(*)), 4) AS p_value
FROM joined
GROUP BY aberration_type
HAVING COUNT(*) >= 5
ORDER BY aberration_type;