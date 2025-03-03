WITH mitelman_cases AS (
  SELECT DISTINCT `RefNo`, `CaseNo`
  FROM `mitelman-db.prod.Cytogen`
  WHERE `Morph` = '3111' AND `Topo` = '0401'
),
mitelman_total_cases AS (
  SELECT COUNT(*) AS total_cases
  FROM mitelman_cases
),
mitelman_abnormalities AS (
  SELECT
    mc.`RefNo`,
    mc.`CaseNo`,
    REGEXP_REPLACE(cc.`Chr`, '^chr', '') AS chromosome,
    cc.`Start`,
    cc.`End`,
    cc.`Type`
  FROM `mitelman-db.prod.CytoConverted` cc
  JOIN mitelman_cases mc
    ON cc.`RefNo` = mc.`RefNo` AND cc.`CaseNo` = mc.`CaseNo`
  WHERE cc.`Start` IS NOT NULL AND cc.`End` IS NOT NULL
    AND cc.`Type` IN ('Gain', 'Loss')
),
cytoband_boundaries AS (
  SELECT
    REGEXP_REPLACE(chromosome, '^chr', '') AS chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop
  FROM `mitelman-db.prod.CytoBands_hg38`
),
mitelman_with_cytoband AS (
  SELECT
    ma.`RefNo`,
    ma.`CaseNo`,
    ma.`chromosome`,
    cb.`cytoband_name`,
    ma.`Type`
  FROM mitelman_abnormalities ma
  JOIN cytoband_boundaries cb
    ON ma.`chromosome` = cb.`chromosome`
    AND ma.`End` >= cb.`hg38_start`
    AND ma.`Start` <= cb.`hg38_stop`
),
mitelman_cytoband_counts AS (
  SELECT
    mwc.chromosome,
    mwc.cytoband_name,
    mwc.Type,
    COUNT(DISTINCT CONCAT(mwc.RefNo, '-', mwc.CaseNo)) AS case_count
  FROM mitelman_with_cytoband mwc
  GROUP BY mwc.chromosome, mwc.cytoband_name, mwc.Type
),
mitelman_cytoband_freq AS (
  SELECT
    mcc.chromosome,
    mcc.cytoband_name,
    mcc.Type,
    SAFE_DIVIDE(mcc.case_count, mtc.total_cases) AS freq
  FROM mitelman_cytoband_counts mcc
  CROSS JOIN mitelman_total_cases mtc
),
tcga_samples AS (
  SELECT DISTINCT sample_barcode
  FROM `isb-cgc.TCGA_bioclin_v0.Biospecimen`
  WHERE project_short_name = 'TCGA-BRCA'
),
tcga_total_samples AS (
  SELECT COUNT(*) AS total_samples FROM tcga_samples
),
tcga_segments AS (
  SELECT
    s.sample_barcode,
    REGEXP_REPLACE(s.chromosome, '^chr', '') AS chromosome,
    s.start_pos AS start_position,
    s.end_pos AS end_position,
    s.segment_mean
  FROM `isb-cgc.TCGA_hg38_data_v0.Copy_Number_Segment_Masked` s
  WHERE s.sample_barcode IN (SELECT sample_barcode FROM tcga_samples)
),
tcga_segments_with_cytoband AS (
  SELECT
    ts.sample_barcode,
    ts.chromosome,
    cb.cytoband_name,
    ts.segment_mean
  FROM tcga_segments ts
  JOIN cytoband_boundaries cb
    ON ts.chromosome = cb.chromosome
    AND ts.end_position >= cb.hg38_start
    AND ts.start_position <= cb.hg38_stop
),
tcga_cytoband_calls AS (
  SELECT DISTINCT
    sc.sample_barcode,
    sc.chromosome,
    sc.cytoband_name,
    CASE
      WHEN sc.segment_mean > 0.3 THEN 'Gain'
      WHEN sc.segment_mean < -0.3 THEN 'Loss'
    END AS Type
  FROM tcga_segments_with_cytoband sc
  WHERE ABS(sc.segment_mean) > 0.3
    AND sc.chromosome IN ('1','2','3','4','5','6','7','8','9','10','11','12',
                          '13','14','15','16','17','18','19','20','21','22','X','Y')
),
tcga_cytoband_counts AS (
  SELECT
    tcc.chromosome,
    tcc.cytoband_name,
    tcc.Type,
    COUNT(DISTINCT tcc.sample_barcode) AS sample_count
  FROM tcga_cytoband_calls tcc
  GROUP BY tcc.chromosome, tcc.cytoband_name, tcc.Type
),
tcga_cytoband_freq AS (
  SELECT
    tcc.chromosome,
    tcc.cytoband_name,
    tcc.Type,
    SAFE_DIVIDE(tcc.sample_count, tts.total_samples) AS freq
  FROM tcga_cytoband_counts tcc
  CROSS JOIN tcga_total_samples tts
),
correlation_data AS (
  SELECT
    mcf.chromosome,
    mcf.cytoband_name,
    mcf.freq AS mitelman_freq,
    tcf.freq AS tcga_freq
  FROM mitelman_cytoband_freq mcf
  JOIN tcga_cytoband_freq tcf
    ON mcf.chromosome = tcf.chromosome
    AND mcf.cytoband_name = tcf.cytoband_name
    AND mcf.Type = tcf.Type
  WHERE mcf.Type = 'Gain'
),
correlation_per_chromosome AS (
  SELECT
    cd.chromosome,
    CORR(cd.mitelman_freq, cd.tcga_freq) AS pearson_corr,
    COUNT(*) AS n
  FROM correlation_data cd
  GROUP BY cd.chromosome
)
SELECT
  chromosome,
  ROUND(pearson_corr, 4) AS Pearson_correlation_coefficient,
  `isb-cgc-bq.functions.corr_pvalue_current`(pearson_corr, n) AS p_value
FROM correlation_per_chromosome
WHERE n >= 5
ORDER BY chromosome;