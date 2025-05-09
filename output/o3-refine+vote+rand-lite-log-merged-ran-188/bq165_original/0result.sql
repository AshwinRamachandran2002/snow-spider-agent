--  Frequency of copy‑number changes (breast cancer, morph = 3111 AND topo = 0401)
WITH
/* -------------------------------------------------------------------- */
/* 1.  Cohort : all (RefNo,CaseNo) pairs that meet the required disease */
/* -------------------------------------------------------------------- */
cohort AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  TRIM(Morph) = '3111'            -- breast cancer morphology
    AND  TRIM(Topo)  = '0401'            -- adenocarcinoma topography
),
total_samples AS ( SELECT COUNT(*) AS n FROM cohort ),

/* -------------------------------------------------------------------- */
/* 2.  CytoConverter segments that belong to the cohort,                 */
/*     classified into 4 copy‑number categories                          */
/* -------------------------------------------------------------------- */
segments AS (
  SELECT
      cc.RefNo,
      cc.CaseNo,
      cc.Chr                         AS chromosome,
      cc.Start,
      cc.End,
      CASE
          WHEN LOWER(cc.Type) LIKE '%amp%'                                   THEN 'Amplification'
          WHEN LOWER(cc.Type) LIKE '%homdel%' OR LOWER(cc.Type) LIKE '%homloss%' THEN 'HomozygousDeletion'
          WHEN LOWER(cc.Type) LIKE '%gain%'                                   THEN 'Gain'
          WHEN LOWER(cc.Type) LIKE '%loss%' OR LOWER(cc.Type) LIKE '%del%'    THEN 'Loss'
          ELSE 'Other'
      END AS event_cat
  FROM   `mitelman-db.prod.CytoConverted` cc
  JOIN   cohort  USING (RefNo, CaseNo)
  WHERE  cc.Type IS NOT NULL
),
/* -------------------------------------------------------------------- */
/* 3.  Overlap each segment with hg38 cytobands                          */
/* -------------------------------------------------------------------- */
seg_band AS (
  SELECT
      s.RefNo,
      s.CaseNo,
      s.event_cat,
      b.chromosome      AS band_chr,
      b.cytoband_name   AS band_name,
      b.hg38_start,
      b.hg38_stop
  FROM   segments s
  JOIN   `mitelman-db.prod.CytoBands_hg38` b
         ON b.chromosome = s.chromosome               -- same chromosome
        AND s.Start < b.hg38_stop                     -- interval overlap
        AND s.End   > b.hg38_start
  WHERE  s.event_cat IN ('Amplification','Gain','Loss','HomozygousDeletion')
),
/* -------------------------------------------------------------------- */
/* 4.  Count distinct samples with each event type per band              */
/* -------------------------------------------------------------------- */
band_counts AS (
  SELECT
      band_chr        AS chromosome,
      band_name       AS cytoband,
      hg38_start,
      hg38_stop,
      COUNT(DISTINCT IF(event_cat='Amplification',      CONCAT(RefNo,'#',CaseNo), NULL)) AS ampl_cnt,
      COUNT(DISTINCT IF(event_cat='Gain',               CONCAT(RefNo,'#',CaseNo), NULL)) AS gain_cnt,
      COUNT(DISTINCT IF(event_cat='Loss',               CONCAT(RefNo,'#',CaseNo), NULL)) AS loss_cnt,
      COUNT(DISTINCT IF(event_cat='HomozygousDeletion', CONCAT(RefNo,'#',CaseNo), NULL)) AS homdel_cnt
  FROM   seg_band
  GROUP  BY chromosome, cytoband, hg38_start, hg38_stop
),
/* -------------------------------------------------------------------- */
/* 5.  Add percentages                                                   */
/* -------------------------------------------------------------------- */
band_freq AS (
  SELECT
      bc.*,
      ROUND(100 * ampl_cnt  / ts.n, 2) AS ampl_pct,
      ROUND(100 * gain_cnt   / ts.n, 2) AS gain_pct,
      ROUND(100 * loss_cnt   / ts.n, 2) AS loss_pct,
      ROUND(100 * homdel_cnt / ts.n, 2) AS homdel_pct
  FROM band_counts bc
  CROSS JOIN total_samples ts
)
/* -------------------------------------------------------------------- */
/* 6.  Final ordered result                                              */
/* -------------------------------------------------------------------- */
SELECT
    chromosome,
    cytoband,
    hg38_start,
    hg38_stop,
    ampl_cnt  AS amplification_samples,
    ampl_pct  AS amplification_freq_pct,
    gain_cnt  AS gain_samples,
    gain_pct  AS gain_freq_pct,
    loss_cnt  AS loss_samples,
    loss_pct  AS loss_freq_pct,
    homdel_cnt AS homoz_del_samples,
    homdel_pct AS homoz_del_freq_pct
FROM  band_freq
ORDER BY
  CASE
      WHEN chromosome = 'chrX' THEN 23
      WHEN chromosome = 'chrY' THEN 24
      ELSE CAST(REGEXP_REPLACE(chromosome, r'^chr', '') AS INT64)
  END,
  hg38_start,
  hg38_stop;