/*---------------------------------------------------------------------------
  Frequency of copy-number events in breast-cancer adenocarcinoma cases
  (Morphology = '3111'  AND  Topography = '0401')
---------------------------------------------------------------------------*/
WITH
/* 1) cohort of breast-cancer adenocarcinoma cases ----------------------- */
cohort AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111'
    AND Topo  = '0401'
),
total_cohort AS (                          -- number of unique cases
  SELECT COUNT(*) AS n_cases
  FROM cohort
),

/* 2) CytoConverter segments that belong to the cohort ------------------- */
segments AS (
  SELECT  cc.RefNo,
          cc.CaseNo,
          LOWER(cc.Type)                   AS raw_type,
          cc.Chr                           AS chromosome,
          cc.Start                         AS seg_start,
          cc.End                           AS seg_end
  FROM `mitelman-db.prod.CytoConverted` AS cc
  JOIN cohort USING (RefNo, CaseNo)
),

/* 3) Overlap segments ↔ cytobands & classify the copy-number event ------ */
band_hits AS (
  SELECT
      cb.chromosome,
      cb.cytoband_name,
      cb.hg38_start,
      cb.hg38_stop,
      s.RefNo,
      s.CaseNo,
      CASE
        WHEN raw_type IN ('amp','amplification','high-level gain')   THEN 'Amplification'
        WHEN raw_type = 'gain'                                       THEN 'Gain'
        WHEN raw_type IN ('homodel','homodeletion','homdel')         THEN 'HomozygousDeletion'
        WHEN raw_type = 'loss'                                       THEN 'Loss'
        ELSE NULL
      END AS event_class
  FROM segments AS s
  JOIN `mitelman-db.prod.CytoBands_hg38` AS cb
    ON  s.chromosome = cb.chromosome
   AND s.seg_start  < cb.hg38_stop
   AND s.seg_end    > cb.hg38_start
),

/* 4) count DISTINCT cases with each event class per cytoband ------------ */
band_event_counts AS (
  SELECT
      chromosome,
      cytoband_name,
      hg38_start,
      hg38_stop,
      event_class,
      COUNT(DISTINCT CONCAT(RefNo,'|',CaseNo)) AS n_cases
  FROM band_hits
  WHERE event_class IS NOT NULL
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop, event_class
),

/* 5) pivot counts so each band has 4 columns ---------------------------- */
band_pivot AS (
  SELECT
      chromosome,
      cytoband_name,
      hg38_start,
      hg38_stop,
      COALESCE(SUM(CASE WHEN event_class = 'Amplification'      THEN n_cases END),0) AS amplification_cases,
      COALESCE(SUM(CASE WHEN event_class = 'Gain'               THEN n_cases END),0) AS gain_cases,
      COALESCE(SUM(CASE WHEN event_class = 'Loss'               THEN n_cases END),0) AS loss_cases,
      COALESCE(SUM(CASE WHEN event_class = 'HomozygousDeletion' THEN n_cases END),0) AS homdel_cases
  FROM band_event_counts
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop
),

/* 6) attach frequencies ------------------------------------------------- */
band_freq AS (
  SELECT
      bp.*,
      ROUND(100.0 * amplification_cases / tc.n_cases, 2) AS amplification_freq,
      ROUND(100.0 * gain_cases          / tc.n_cases, 2) AS gain_freq,
      ROUND(100.0 * loss_cases          / tc.n_cases, 2) AS loss_freq,
      ROUND(100.0 * homdel_cases        / tc.n_cases, 2) AS homdel_freq
  FROM band_pivot AS bp
  CROSS JOIN total_cohort AS tc
)

/* 7) final result incl. zero-event bands, ordered properly -------------- */
SELECT
    cb.chromosome,
    cb.cytoband_name,
    cb.hg38_start,
    cb.hg38_stop,
    IFNULL(bf.amplification_cases, 0) AS amplification_cases,
    IFNULL(bf.amplification_freq , 0) AS amplification_freq,
    IFNULL(bf.gain_cases         , 0) AS gain_cases,
    IFNULL(bf.gain_freq          , 0) AS gain_freq,
    IFNULL(bf.loss_cases         , 0) AS loss_cases,
    IFNULL(bf.loss_freq          , 0) AS loss_freq,
    IFNULL(bf.homdel_cases       , 0) AS homdel_cases,
    IFNULL(bf.homdel_freq        , 0) AS homdel_freq
FROM `mitelman-db.prod.CytoBands_hg38` AS cb
LEFT JOIN band_freq AS bf
  ON cb.chromosome    = bf.chromosome
 AND cb.cytoband_name = bf.cytoband_name
ORDER BY
  CASE
    WHEN cb.chromosome = 'chrX' THEN 23
    WHEN cb.chromosome = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(cb.chromosome, r'^chr', '') AS INT64)
  END,
  cb.hg38_start;