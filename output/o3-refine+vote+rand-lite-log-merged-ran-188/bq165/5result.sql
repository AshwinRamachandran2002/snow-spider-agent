/*-----------------------------------------------------------
  Breast-cancer / Adenocarcinoma cohort
  Copy-number landscape per cytogenetic band (hg38)

  – Cohort definition : Cytogen.Morph = '3111'  (breast cancer)
                        OR TRIM(Cytogen.Topo) = '0401' (adenocarcinoma)
  – CNV source        : CytoConverted (Start/End, Type)
  – Band reference    : CytoBands_hg38
  – Requested output  : absolute number of events and their
                        frequency (%) per band for
                        • Amplification  (Type = 'Amplification')
                        • Gain           (Type = 'Gain')
                        • Loss           (Type = 'Loss')
                        • Homo-del       (Type = 'Homozygous deletion')
  – Ordering          : chromosome ordinal 1-24 (X=23,Y=24),
                        then band start position (hg38_start)
-----------------------------------------------------------*/
WITH
/* 1)  all (RefNo,CaseNo) that belong to the target diseases  */
cohort AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  TRIM(Morph) = '3111'
     OR  TRIM(Topo)  = '0401'
),

/* 2)  every CNV segment that overlaps a cytogenetic band      */
events AS (
  SELECT
    ccv.RefNo,
    ccv.CaseNo,
    cb.chromosome,          -- e.g. 'chr14'
    cb.cytoband_name,       -- e.g. '14q32'
    cb.hg38_start,
    cb.hg38_stop,
    ccv.Type                -- Gain / Loss / Amplification / Homozygous deletion
  FROM   `mitelman-db.prod.CytoConverted`    AS ccv
  JOIN   cohort                              USING (RefNo, CaseNo)
  JOIN   `mitelman-db.prod.CytoBands_hg38`   AS cb
         ON  ccv.Chr               = cb.chromosome
        AND ccv.Start  < cb.hg38_stop          -- interval overlap (open/closed)
        AND ccv.End    > cb.hg38_start
),

/* 3)  number of DISTINCT cases that have *any* CNV in the band */
band_totals AS (
  SELECT
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    COUNT(DISTINCT CONCAT(RefNo,'-',CaseNo)) AS n_cases
  FROM   events
  GROUP  BY chromosome, cytoband_name, hg38_start, hg38_stop
),

/* 4)  raw event counts per CNV class                          */
band_counts AS (
  SELECT
    chromosome,
    cytoband_name,
    hg38_start,
    hg38_stop,
    SUM(CASE WHEN Type = 'Amplification'        THEN 1 ELSE 0 END) AS amp_cnt,
    SUM(CASE WHEN Type = 'Gain'                 THEN 1 ELSE 0 END) AS gain_cnt,
    SUM(CASE WHEN Type = 'Loss'                 THEN 1 ELSE 0 END) AS loss_cnt,
    SUM(CASE WHEN Type = 'Homozygous deletion'  THEN 1 ELSE 0 END) AS homdel_cnt
  FROM   events
  GROUP  BY chromosome, cytoband_name, hg38_start, hg38_stop
)

/* 5)  final report  ------------------------------------------*/
SELECT
  bc.chromosome,
  bc.cytoband_name,
  bc.hg38_start,
  bc.hg38_stop,
  bc.amp_cnt,
  ROUND(100 * SAFE_DIVIDE(bc.amp_cnt , bt.n_cases), 2) AS amp_pct,
  bc.gain_cnt,
  ROUND(100 * SAFE_DIVIDE(bc.gain_cnt, bt.n_cases), 2) AS gain_pct,
  bc.loss_cnt,
  ROUND(100 * SAFE_DIVIDE(bc.loss_cnt, bt.n_cases), 2) AS loss_pct,
  bc.homdel_cnt,
  ROUND(100 * SAFE_DIVIDE(bc.homdel_cnt, bt.n_cases), 2) AS homdel_pct
FROM   band_counts  AS bc
JOIN   band_totals  AS bt
       USING (chromosome, cytoband_name, hg38_start, hg38_stop)
ORDER BY
  -- numeric chromosome order: 1-22, X=23, Y=24
  CASE
    WHEN bc.chromosome = 'chrX' THEN 23
    WHEN bc.chromosome = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(bc.chromosome, r'^chr', '') AS INT64)
  END,
  bc.hg38_start,
  bc.hg38_stop;