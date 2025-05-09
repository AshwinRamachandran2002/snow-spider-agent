/*  Frequency of copy-number abnormalities per cytoband
    in breast-cancer (Morphology = 3111) or adenocarcinoma
    (Topology = 0401) samples                                          */

WITH cohort AS (                   -- total number of distinct samples
  SELECT COUNT(DISTINCT CONCAT(`RefNo`, '-', `CaseNo`)) AS total_samples
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  `Morph` = '3111'
     OR  `Topo`  = '0401'
),

band_class_counts AS (             -- samples per cytoband & CNV class
  SELECT
    cb.`chromosome`,
    cb.`cytoband_name`,
    cb.`hg38_start`,
    cb.`hg38_stop`,
    CASE
      WHEN LOWER(cc.`Type`) LIKE '%amp%' THEN 'Amplification'
      WHEN LOWER(cc.`Type`)           = 'gain' THEN 'Gain'
      WHEN LOWER(cc.`Type`)           = 'loss' THEN 'Loss'
      ELSE                                    'HomoDel'
    END                                                   AS copy_number_state,
    COUNT(DISTINCT CONCAT(cc.`RefNo`, '-', cc.`CaseNo`))  AS sample_count
  FROM   `mitelman-db.prod.CytoConverted`  AS cc
  JOIN   `mitelman-db.prod.Cytogen`        AS cg
         ON  cc.`RefNo`  = cg.`RefNo`
         AND cc.`CaseNo` = cg.`CaseNo`
  JOIN   `mitelman-db.prod.CytoBands_hg38` AS cb
         ON  cc.`Chr`   = cb.`chromosome`
         AND cc.`Start` < cb.`hg38_stop`
         AND cc.`End`   > cb.`hg38_start`
  WHERE  cg.`Morph` = '3111'
     OR  cg.`Topo`  = '0401'
  GROUP  BY cb.`chromosome`,
            cb.`cytoband_name`,
            cb.`hg38_start`,
            cb.`hg38_stop`,
            copy_number_state
)

SELECT
  bcc.`chromosome`,
  bcc.`cytoband_name`,
  bcc.`hg38_start`,
  bcc.`hg38_stop`,
  bcc.`copy_number_state`,
  bcc.`sample_count`,
  ROUND(100.0 * bcc.`sample_count` / coh.`total_samples`, 2) AS frequency_pct
FROM   band_class_counts AS bcc
CROSS  JOIN cohort        AS coh
ORDER BY
  CASE
    WHEN bcc.`chromosome` = 'chrX' THEN 23
    WHEN bcc.`chromosome` = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(bcc.`chromosome`, r'^chr', '') AS INT64)
  END,
  bcc.`hg38_start`,
  bcc.`hg38_stop`,
  bcc.`copy_number_state`;