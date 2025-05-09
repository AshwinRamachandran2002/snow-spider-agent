/*  Frequency of copy-number events in breast-cancer (Morph = 3111)
    and adenocarcinoma (Topo = 0401) cohorts, computed per cytogenetic
    band using CytoConverter genomic coordinates.                       */

WITH cohort AS (            -- total number of distinct samples
  SELECT COUNT(DISTINCT CONCAT(cc.RefNo,'|',cc.CaseNo,'|',cc.InvNo,'|',cc.Clone)) AS n_total
  FROM   `mitelman-db.prod.CytoConverted` AS cc
  JOIN   `mitelman-db.prod.Cytogen`       AS cg
    ON   cc.RefNo  = cg.RefNo
   AND   cc.CaseNo = cg.CaseNo
  WHERE  cg.Morph = '3111'                       -- breast cancer
     OR  TRIM(cg.Topo) = '0401'                  -- adenocarcinoma
),

events AS (            -- copy-number events overlapping each band
  SELECT
    cb.cytoband_name,
    MIN(cc.ChrOrd) AS ChrOrd,
    cb.hg38_start  AS BandStart,
    cb.hg38_stop   AS BandEnd,
    CASE
      WHEN LOWER(cc.Type) LIKE '%twocopygain%'  OR LOWER(cc.Type) LIKE '%amp%'  THEN 'AMPLIFICATION'
      WHEN LOWER(cc.Type) = 'gain'                                                 THEN 'GAIN'
      WHEN LOWER(cc.Type) = 'loss'                                                 THEN 'LOSS'
      WHEN LOWER(cc.Type) LIKE '%twocopyloss%' OR LOWER(cc.Type) LIKE '%homo%'    THEN 'HOMOZYGOUS_DELETION'
      ELSE 'OTHER'
    END AS copy_class,
    COUNT(DISTINCT CONCAT(cc.RefNo,'|',cc.CaseNo,'|',cc.InvNo,'|',cc.Clone)) AS num_samples
  FROM   `mitelman-db.prod.CytoConverted` AS cc
  JOIN   `mitelman-db.prod.Cytogen`       AS cg
    ON   cc.RefNo  = cg.RefNo
   AND   cc.CaseNo = cg.CaseNo
  JOIN   `mitelman-db.prod.CytoBands_hg38` AS cb
    ON   cb.chromosome = cc.Chr
   AND   cc.Start < cb.hg38_stop           -- interval overlap
   AND   cc.End   > cb.hg38_start
  WHERE  cg.Morph = '3111'
     OR  TRIM(cg.Topo) = '0401'
  GROUP BY
    cb.cytoband_name, BandStart, BandEnd, copy_class
)

SELECT
  e.cytoband_name,
  e.ChrOrd,
  e.BandStart,
  e.BandEnd,
  e.copy_class,
  e.num_samples,
  ROUND(100.0 * e.num_samples / c.n_total, 2) AS frequency_pct
FROM   events  AS e
CROSS  JOIN cohort AS c
WHERE  e.copy_class IN ('AMPLIFICATION','GAIN','LOSS','HOMOZYGOUS_DELETION')
ORDER  BY e.ChrOrd, e.BandStart, e.BandEnd, e.copy_class;