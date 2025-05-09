-- frequency of arm‑level copy‑number events for
--   • breast cancer  (Morphology = 3111)
--   • adenocarcinoma (Topography = 0401)

WITH -------------------------------------------------------------------------
cohort_cases AS (          -- all (RefNo,CaseNo) that belong to the cohort
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111'              -- breast cancer
     OR Topo  = '0401'              -- adenocarcinoma
),

events AS (                -- CytoConverter segments for the cohort
  SELECT
      c.RefNo ,
      c.CaseNo,
      c.InvNo ,
      c.Clone ,
      CONCAT(c.RefNo,'_',c.CaseNo,'_',c.InvNo,'_',c.Clone) AS sample_id,
      c.Chr                              AS chromosome,
      c.Start ,
      c.End   ,
      /* harmonise CytoConverter “Type” to four biological categories          */
      CASE
        WHEN LOWER(c.Type) LIKE '%amp%'         OR c.Type IN ('HighGain','Gain2','Amplification','Gain>1')
          THEN 'Amplification'                  -- >1 extra copy
        WHEN LOWER(c.Type) IN ('gain','gain1','gain_1','cngain')
          THEN 'Gain'                           -- +1 copy
        WHEN LOWER(c.Type) LIKE '%hom'          OR c.Type IN ('Loss2','HomoDel','HomDel','Del2')
          THEN 'HomoDel'                        -- –2 copies
        WHEN LOWER(c.Type) IN ('loss','del','loss1','loss_1','cnloss')
          THEN 'Loss'                           -- –1 copy
      END                                       AS category
  FROM `mitelman-db.prod.CytoConverted`   AS c
  JOIN cohort_cases                       AS k USING (RefNo,CaseNo)
  WHERE c.Type IS NOT NULL
),
band_overlap AS (          -- map every CNA segment to the hg38 cytoband(s) it overlaps
  SELECT
      e.sample_id,
      e.category,
      b.chromosome,
      b.cytoband_name,
      b.hg38_start,
      b.hg38_stop
  FROM events                 AS e
  JOIN `mitelman-db.prod.CytoBands_hg38` AS b
       ON  b.chromosome = e.chromosome
       AND e.End   > b.hg38_start        -- interval‑overlap test
       AND e.Start < b.hg38_stop
  WHERE category IS NOT NULL
),
band_counts AS (           -- number of UNIQUE samples with an event in the band
  SELECT
      chromosome,
      cytoband_name,
      hg38_start,
      hg38_stop,
      category,
      COUNT(DISTINCT sample_id) AS n_samples
  FROM band_overlap
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop, category
),
band_matrix AS (           -- pivot the four categories into columns
  SELECT
      chromosome,
      cytoband_name,
      hg38_start,
      hg38_stop,
      SUM(CASE WHEN category='Amplification' THEN n_samples ELSE 0 END) AS amp_n,
      SUM(CASE WHEN category='Gain'          THEN n_samples ELSE 0 END) AS gain_n,
      SUM(CASE WHEN category='Loss'          THEN n_samples ELSE 0 END) AS loss_n,
      SUM(CASE WHEN category='HomoDel'       THEN n_samples ELSE 0 END) AS homdel_n
  FROM band_counts
  GROUP BY chromosome, cytoband_name, hg38_start, hg38_stop
),
tot_samples AS (          -- denominator = all unique (Ref,Case,Inv,Clone) in cohort
  SELECT COUNT(DISTINCT CONCAT(RefNo,'_',CaseNo,'_',InvNo,'_',Clone)) AS n_total
  FROM `mitelman-db.prod.CytoConverted` c
  JOIN cohort_cases k USING (RefNo,CaseNo)
)

SELECT
    bm.chromosome,
    bm.cytoband_name,
    bm.hg38_start,
    bm.hg38_stop,
    bm.amp_n                                                  AS amplification_count,
    ROUND(100.0*bm.amp_n    /ts.n_total,2)                    AS amplification_freq_pct,
    bm.gain_n                                                 AS gain_count,
    ROUND(100.0*bm.gain_n   /ts.n_total,2)                    AS gain_freq_pct,
    bm.loss_n                                                 AS loss_count,
    ROUND(100.0*bm.loss_n   /ts.n_total,2)                    AS loss_freq_pct,
    bm.homdel_n                                               AS homdel_count,
    ROUND(100.0*bm.homdel_n /ts.n_total,2)                    AS homdel_freq_pct
FROM band_matrix bm
CROSS JOIN tot_samples ts

-- sort by chromosome (1‑22,X,Y) then by cytoband genomic start
ORDER BY
  CASE
    WHEN bm.chromosome = 'chrX' THEN 23
    WHEN bm.chromosome = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(bm.chromosome,'chr','') AS INT64)
  END,
  bm.hg38_start,
  bm.hg38_stop;