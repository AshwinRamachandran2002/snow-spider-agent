/* chromosomal‑band frequencies of copy‑number changes in
   breast‑carcinoma (Morph = '3111') and adenocarcinoma
   (Topo = '0401') samples                                         */

WITH cohort AS (
  -- all CytoConverter segments that belong to the cohort
  SELECT DISTINCT
         CONCAT(cc.RefNo, ':', cc.CaseNo, ':', cc.InvNo, ':', cc.Clone) AS sample_id,
         cc.Chr,
         cc.Start,
         cc.End,
         cc.Type
  FROM   `mitelman-db.prod.CytoConverted` AS cc
  JOIN   `mitelman-db.prod.Cytogen`       AS cg
    ON   cc.RefNo  = cg.RefNo
   AND   cc.CaseNo = cg.CaseNo
  WHERE  cg.Morph = '3111'          -- breast carcinoma
     OR  cg.Topo  = '0401'          -- adenocarcinoma, site unspecified
),
total AS (
  -- total number of unique samples in the cohort
  SELECT COUNT(DISTINCT sample_id) AS total_n
  FROM   cohort
)

SELECT
  cb.chromosome,
  cb.cytoband_name,
  cb.hg38_start,
  cb.hg38_stop,

  -- raw counts (distinct samples) for each alteration class
  COUNT(DISTINCT IF(c.Type = 'Amp'   , c.sample_id, NULL)) AS n_amp,
  COUNT(DISTINCT IF(c.Type = 'Gain'  , c.sample_id, NULL)) AS n_gain,
  COUNT(DISTINCT IF(c.Type = 'Loss'  , c.sample_id, NULL)) AS n_loss,
  COUNT(DISTINCT IF(c.Type = 'HomDel', c.sample_id, NULL)) AS n_homdel,

  -- percentages w.r.t. the whole cohort (rounded to 2 decimals)
  ROUND(100 * COUNT(DISTINCT IF(c.Type = 'Amp'   , c.sample_id, NULL)) / t.total_n, 2) AS freq_amp_pct,
  ROUND(100 * COUNT(DISTINCT IF(c.Type = 'Gain'  , c.sample_id, NULL)) / t.total_n, 2) AS freq_gain_pct,
  ROUND(100 * COUNT(DISTINCT IF(c.Type = 'Loss'  , c.sample_id, NULL)) / t.total_n, 2) AS freq_loss_pct,
  ROUND(100 * COUNT(DISTINCT IF(c.Type = 'HomDel', c.sample_id, NULL)) / t.total_n, 2) AS freq_homdel_pct

FROM   `mitelman-db.prod.CytoBands_hg38` AS cb
LEFT JOIN cohort AS c
       ON cb.chromosome = c.Chr
      AND cb.hg38_start < c.End
      AND cb.hg38_stop  > c.Start
CROSS JOIN total AS t

GROUP BY
  cb.chromosome,
  cb.cytoband_name,
  cb.hg38_start,
  cb.hg38_stop,
  t.total_n

-- genomic ordering: chr1‑chr22, chrX, chrY
ORDER BY
  CASE
      WHEN REGEXP_EXTRACT(cb.chromosome, r'chr(\d+)') IS NOT NULL
           THEN CAST(REGEXP_EXTRACT(cb.chromosome, r'chr(\d+)') AS INT64)
      WHEN cb.chromosome = 'chrX' THEN 23
      WHEN cb.chromosome = 'chrY' THEN 24
      ELSE 25
  END,
  cb.hg38_start,
  cb.hg38_stop;