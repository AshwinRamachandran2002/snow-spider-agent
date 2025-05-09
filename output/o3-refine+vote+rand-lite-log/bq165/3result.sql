/*  -----------------------------------------------------------
    Frequency of copy‑number abnormalities per cytogenetic band
    – cohort: breast cancer (Morph = 3111) OR adenocarcinoma (Topo = 0401)
    – events taken from CytoConverted (hg38 coordinates)
    – amplification : Type IN ('Amp' , 'Amplification')
      gain          : Type =  'Gain'
      loss          : Type =  'Loss'
      homo‑del      : Type IN ('HD'  , 'HomozygousDeletion')
    ----------------------------------------------------------- */

WITH
/* 1. Cases belonging to the requested cohort                         */
cohort AS (
  SELECT DISTINCT RefNo , CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE TRIM(Morph) = '3111'         -- breast cancer
     OR TRIM(Topo)  = '0401'         -- adenocarcinoma
),

/* 2. Total number of cases – denominator for the percentage          */
total_cases AS (
  SELECT COUNT(DISTINCT CONCAT(RefNo,':',CaseNo)) AS n_cases
  FROM cohort
),

/* 3. Copy‑number segments for the cohort, categorised                */
segments AS (
  SELECT
      cc.RefNo ,
      cc.CaseNo ,
      cc.Chr          AS chromosome ,
      cc.Start        AS seg_start ,
      cc.End          AS seg_end ,
      CASE
        WHEN LOWER(cc.Type) IN ('amp','amplification')              THEN 'AMPLIFICATION'
        WHEN LOWER(cc.Type) =  'gain'                               THEN 'GAIN'
        WHEN LOWER(cc.Type) =  'loss'                               THEN 'LOSS'
        WHEN LOWER(cc.Type) IN ('hd','homozygousdeletion')          THEN 'HOM_DEL'
        ELSE NULL
      END AS event_class
  FROM cohort c
  JOIN `mitelman-db.prod.CytoConverted` cc
    ON cc.RefNo  = c.RefNo
   AND cc.CaseNo = c.CaseNo
  WHERE cc.Type IS NOT NULL
),

/* 4. Overlap each segment with its cytogenetic bands                 */
band_overlap AS (
  SELECT
      b.chromosome ,
      b.cytoband_name ,
      b.hg38_start ,
      b.hg38_stop ,
      s.RefNo ,
      s.CaseNo ,
      s.event_class
  FROM segments s
  JOIN `mitelman-db.prod.CytoBands_hg38` b
    ON b.chromosome = s.chromosome
   AND s.event_class IS NOT NULL
   AND s.seg_start < b.hg38_stop      -- interval overlap
   AND s.seg_end   > b.hg38_start
),

/* 5. Count how many distinct cases show each event in every band     */
band_counts AS (
  SELECT
      chromosome ,
      cytoband_name ,
      hg38_start ,
      hg38_stop ,
      COUNT(DISTINCT CASE WHEN event_class = 'AMPLIFICATION'
                          THEN CONCAT(RefNo,':',CaseNo) END) AS amplification_n ,
      COUNT(DISTINCT CASE WHEN event_class = 'GAIN'
                          THEN CONCAT(RefNo,':',CaseNo) END) AS gain_n ,
      COUNT(DISTINCT CASE WHEN event_class = 'LOSS'
                          THEN CONCAT(RefNo,':',CaseNo) END) AS loss_n ,
      COUNT(DISTINCT CASE WHEN event_class = 'HOM_DEL'
                          THEN CONCAT(RefNo,':',CaseNo) END) AS hom_del_n
  FROM band_overlap
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop
),

/* 6. Add percentages                                                 */
band_freq AS (
  SELECT
      bc.* ,
      ROUND(100.0 * amplification_n / tc.n_cases , 2) AS amplification_pct ,
      ROUND(100.0 * gain_n           / tc.n_cases , 2) AS gain_pct ,
      ROUND(100.0 * loss_n           / tc.n_cases , 2) AS loss_pct ,
      ROUND(100.0 * hom_del_n        / tc.n_cases , 2) AS hom_del_pct
  FROM band_counts bc
  CROSS JOIN total_cases tc
)

/* 7. Final ordered result                                            */
SELECT
    chromosome ,
    cytoband_name ,
    hg38_start ,
    hg38_stop ,
    amplification_n  AS amplification_cases ,
    amplification_pct ,
    gain_n            AS gain_cases ,
    gain_pct ,
    loss_n            AS loss_cases ,
    loss_pct ,
    hom_del_n         AS hom_del_cases ,
    hom_del_pct
FROM band_freq
ORDER BY
    CASE
      WHEN chromosome = 'chrX' THEN 23
      WHEN chromosome = 'chrY' THEN 24
      WHEN REGEXP_CONTAINS(chromosome, r'chr(\d+)')
           THEN CAST(REGEXP_EXTRACT(chromosome, r'chr(\d+)') AS INT64)
      ELSE 25
    END ,
    hg38_start ,
    hg38_stop ;