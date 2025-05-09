/*--------------------------------------------------------------------
  Pearson correlation (Mitelman vs TCGA) of copy-number events
  — breast carcinoma (Morph = 3111, Topo = 0401 / TCGA-BRCA)
  -------------------------------------------------------------------*/

WITH
/*------------------------------------------------------------------*/
/*  1)  Mitelman cohort and per-chromosome event frequencies         */
/*------------------------------------------------------------------*/
mit_cohort AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE TRIM(Morph) = '3111'      -- breast carcinoma
    AND TRIM(Topo)  = '0401'      -- adenocarcinoma
),
mit_events AS (
  SELECT
    REGEXP_REPLACE(cnv.Chr, r'^chr', '')               AS chromosome,
    cnv.Type                                           AS aberration_type,      -- Amp | Gain | Loss | Del
    COUNT(DISTINCT CONCAT(cnv.RefNo,'|',cnv.CaseNo))   AS n_cases_with_event
  FROM `mitelman-db.prod.CytoConverted` cnv
  JOIN mit_cohort mc
    ON cnv.RefNo = mc.RefNo AND cnv.CaseNo = mc.CaseNo
  GROUP BY chromosome, aberration_type
),
mit_tot AS (SELECT COUNT(*) AS n_total_cases FROM mit_cohort),
mit_freq AS (
  SELECT
    chromosome,
    aberration_type,
    100.0 * n_cases_with_event / mit_tot.n_total_cases AS freq_pct_mitelman
  FROM mit_events, mit_tot
),

/*------------------------------------------------------------------*/
/*  2)  TCGA-BRCA copy-number calls and per-chromosome frequencies   */
/*------------------------------------------------------------------*/
tcga_segments AS (          -- masked copy-number segments (hg38)
  SELECT
    case_barcode,                                    -- already 12-char
    CASE
      WHEN chromosome = '23' THEN 'X'
      WHEN chromosome = '24' THEN 'Y'
      ELSE chromosome
    END                       AS chromosome,
    segment_mean
  FROM `isb-cgc.TCGA_hg38_data_v0.Copy_Number_Segment_Masked`
  WHERE project_short_name = 'TCGA-BRCA'             -- restrict to BRCA
),
tcga_classified AS (        -- classify each segment
  SELECT
    case_barcode,
    chromosome,
    CASE
      WHEN segment_mean >=  0.9 THEN 'Amp'
      WHEN segment_mean >=  0.3 THEN 'Gain'
      WHEN segment_mean <= -0.9 THEN 'Del'
      WHEN segment_mean <= -0.3 THEN 'Loss'
    END AS aberration_type
  FROM tcga_segments
  WHERE ABS(segment_mean) >= 0.3                     -- exclude neutral
),
tcga_events_per_case AS (   -- one flag per case/chromosome/type
  SELECT DISTINCT
    case_barcode,
    chromosome,
    aberration_type
  FROM tcga_classified
  WHERE aberration_type IS NOT NULL
),
tcga_tot AS (
  SELECT COUNT(DISTINCT case_barcode) AS n_total_cases
  FROM tcga_segments
),
tcga_counts AS (
  SELECT
    chromosome,
    aberration_type,
    COUNT(DISTINCT case_barcode) AS n_cases_with_event
  FROM tcga_events_per_case
  GROUP BY chromosome, aberration_type
),
tcga_freq AS (
  SELECT
    chromosome,
    aberration_type,
    100.0 * n_cases_with_event / tcga_tot.n_total_cases AS freq_pct_tcga
  FROM tcga_counts, tcga_tot
),

/*------------------------------------------------------------------*/
/*  3)  Join Mitelman & TCGA frequencies                             */
/*------------------------------------------------------------------*/
joined AS (
  SELECT
    mf.chromosome,
    mf.aberration_type,
    mf.freq_pct_mitelman,
    tf.freq_pct_tcga
  FROM mit_freq mf
  JOIN tcga_freq tf
    ON mf.chromosome      = tf.chromosome
   AND mf.aberration_type = tf.aberration_type
),

/*------------------------------------------------------------------*/
/*  4)  Pearson correlation across chromosomes for each event type  */
/*------------------------------------------------------------------*/
per_type_corr AS (
  SELECT
    aberration_type                            AS AberrationType,
    COUNT(*)                                   AS n_chromosomes,
    CORR(freq_pct_mitelman, freq_pct_tcga)     AS pearson_r
  FROM joined
  GROUP BY AberrationType
  HAVING n_chromosomes >= 5                    -- require ≥5 data-points
)

/*------------------------------------------------------------------*/
/*  5)  Final report                                                 */
/*------------------------------------------------------------------*/
SELECT
  AberrationType,
  n_chromosomes,
  pearson_r,
  `isb-cgc-bq.functions.corr_pvalue_current`(pearson_r, n_chromosomes) AS p_value
FROM per_type_corr
ORDER BY AberrationType;