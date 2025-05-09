/*  --------------------------------------------------------------
    Chromosomal copy–number profile for breast‑cancer adenocarcinoma
    (Morphology = ‘3111’  AND  Topology = ‘0401’)

    – For every cytoband (hg38 coordinates) report
         · number of samples with
             · Amplification  (Type = 'Amp')
             · Gain           (Type = 'Gain')
             · Loss           (Type = 'Loss')
             · Hom. deletion  (Type = 'HomoDel')
         · frequency of each category within the cohort
           (percentage of total unique (RefNo,CaseNo) samples, 2 decimals)

    – Output sorted by chromosome order then band start/stop.
----------------------------------------------------------------- */
WITH
/* ---------------------------------------------------------------
   1. Cohort definition  (breast‑cancer adenocarcinoma samples)
---------------------------------------------------------------- */
samples AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  Morph = '3111'
     AND Topo  = '0401'
),
/* ---------------------------------------------------------------
   2. Copy‑number events for the cohort
---------------------------------------------------------------- */
events AS (
  SELECT DISTINCT
         e.RefNo,
         e.CaseNo,
         e.Type,        -- Amp | Gain | Loss | HomoDel
         e.Chr,
         e.Start,
         e.End
  FROM   `mitelman-db.prod.CytoConverted`  e
  JOIN   samples                           s
         ON  e.RefNo  = s.RefNo
         AND e.CaseNo = s.CaseNo
  WHERE  e.Type IN ('Amp','Gain','Loss','HomoDel')
),
/* ---------------------------------------------------------------
   3. Map events to cytobands (any bp overlap)
---------------------------------------------------------------- */
band_events AS (
  SELECT
    b.chromosome,
    b.cytoband_name,
    b.hg38_start,
    b.hg38_stop,
    CASE
      WHEN b.chromosome = 'chrX' THEN 23
      WHEN b.chromosome = 'chrY' THEN 24
      ELSE CAST(REGEXP_REPLACE(b.chromosome, r'^chr','') AS INT64)
    END                            AS chr_order,
    e.Type                         AS event_type,
    CONCAT(CAST(e.RefNo AS STRING),'-',e.CaseNo) AS sample_id
  FROM   events  e
  JOIN   `mitelman-db.prod.CytoBands_hg38`  b
         ON  e.Chr = b.chromosome
         AND e.End   > b.hg38_start         -- overlaps band
         AND e.Start < b.hg38_stop
),
/* ---------------------------------------------------------------
   4. Count distinct samples per band & category
---------------------------------------------------------------- */
band_counts AS (
  SELECT
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    chr_order,

    COUNT(DISTINCT IF(event_type = 'Amp'     , sample_id, NULL)) AS amp_n,
    COUNT(DISTINCT IF(event_type = 'Gain'    , sample_id, NULL)) AS gain_n,
    COUNT(DISTINCT IF(event_type = 'Loss'    , sample_id, NULL)) AS loss_n,
    COUNT(DISTINCT IF(event_type = 'HomoDel' , sample_id, NULL)) AS homdel_n
  FROM   band_events
  GROUP  BY chromosome, cytoband_name, hg38_start, hg38_stop, chr_order
),
/* ---------------------------------------------------------------
   5. Total number of cohort samples
---------------------------------------------------------------- */
tot AS (
  SELECT COUNT(DISTINCT CONCAT(CAST(RefNo AS STRING),'-',CaseNo)) AS n_samples
  FROM   samples
)
/* ---------------------------------------------------------------
   6. Final result with frequencies (%, two decimals)
---------------------------------------------------------------- */
SELECT
  chromosome,
  cytoband_name,
  hg38_start  AS band_start,
  hg38_stop   AS band_end,

  amp_n,
  ROUND(100 * SAFE_DIVIDE(amp_n  , n_samples), 2) AS amp_pct,

  gain_n,
  ROUND(100 * SAFE_DIVIDE(gain_n , n_samples), 2) AS gain_pct,

  loss_n,
  ROUND(100 * SAFE_DIVIDE(loss_n , n_samples), 2) AS loss_pct,

  homdel_n,
  ROUND(100 * SAFE_DIVIDE(homdel_n , n_samples), 2) AS homdel_pct
FROM   band_counts, tot
ORDER  BY chr_order, hg38_start, hg38_stop;