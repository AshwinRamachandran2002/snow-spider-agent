-- Compute Pearson correlations (and p‑values) between Mitelman and TCGA‑BRCA
-- copy‑number aberration frequencies, per aberration category.
-- Aberration categories handled: Amplification, Gain, Loss, Deletion.
-- Only correlations based on ≥ 5 matching chromosomes are reported.

WITH
/* ----------  Mitelman (breast carcinoma: morph 3111, topo 0401)  ---------- */
mit_cases AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111' AND Topo = '0401'
),
mit_by_chr AS (
  SELECT
    cc.ChrOrd                              AS chr_ord,
    cc.Type                                AS aberr_type,          -- Gain/Loss/Amplification/Deletion
    COUNT(DISTINCT CONCAT(cc.RefNo,'-',cc.CaseNo)) AS n_cases_abn
  FROM `mitelman-db.prod.CytoConverted` cc
  JOIN mit_cases mc
    ON cc.RefNo = mc.RefNo AND cc.CaseNo = mc.CaseNo
  WHERE cc.Type IN ('Gain','Loss','Amplification','Deletion')
  GROUP BY chr_ord, aberr_type
),
mit_tot AS (
  SELECT COUNT(*) AS n_cases FROM mit_cases
),
mit_freq AS (
  SELECT
    chr_ord,
    aberr_type,
    n_cases_abn / mit_tot.n_cases AS mit_freq
  FROM mit_by_chr, mit_tot
),

/* ---------------------------  TCGA‑BRCA --------------------------- */
tcga_tot AS (
  SELECT COUNT(DISTINCT sample_barcode) AS n_samples
  FROM `isb-cgc.TCGA_hg38_data_v0.Copy_Number_Segment_Masked`
  WHERE project_short_name = 'TCGA-BRCA'
),
tcga_abn AS (
  /* classify each segment into an aberration category                    */
  SELECT
    CASE
      WHEN chromosome IN ('X','x') THEN 23
      WHEN chromosome IN ('Y','y') THEN 24
      ELSE SAFE_CAST(chromosome AS INT64)
    END                                                     AS chr_ord,
    CASE
      WHEN segment_mean >=  0.90                          THEN 'Amplification'
      WHEN segment_mean >=  0.15  AND segment_mean < 0.90 THEN 'Gain'
      WHEN segment_mean <= -0.90                          THEN 'Deletion'
      WHEN segment_mean <= -0.15 AND segment_mean > -0.90 THEN 'Loss'
    END                                                     AS aberr_type,
    sample_barcode
  FROM `isb-cgc.TCGA_hg38_data_v0.Copy_Number_Segment_Masked`
  WHERE project_short_name = 'TCGA-BRCA'
),
tcga_by_chr AS (
  SELECT
    chr_ord,
    aberr_type,
    COUNT(DISTINCT sample_barcode) AS n_samples_abn
  FROM tcga_abn
  WHERE aberr_type IS NOT NULL AND chr_ord IS NOT NULL
  GROUP BY chr_ord, aberr_type
),
tcga_freq AS (
  SELECT
    chr_ord,
    aberr_type,
    n_samples_abn / tcga_tot.n_samples AS tcga_freq
  FROM tcga_by_chr, tcga_tot
),

/* -------------------  Join & compute correlations  ------------------- */
joined AS (
  SELECT
    m.aberr_type,
    m.chr_ord,
    m.mit_freq,
    t.tcga_freq
  FROM mit_freq m
  JOIN tcga_freq t
    USING (chr_ord, aberr_type)
),
corr_by_type AS (
  SELECT
    aberr_type,
    CORR(mit_freq, tcga_freq) AS pearson_r,
    COUNT(*)                 AS matched_chr
  FROM joined
  GROUP BY aberr_type
)

SELECT
  aberr_type,
  pearson_r,
  `isb-cgc-bq.functions.corr_pvalue_current`(pearson_r, matched_chr) AS p_value,
  matched_chr
FROM corr_by_type
WHERE matched_chr >= 5
ORDER BY aberr_type;