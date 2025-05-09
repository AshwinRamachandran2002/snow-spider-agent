/*---------------------------------------------------------------
  Chromosomal copy‑number abnormality frequencies (per cytoband)
  for breast cancer (Morphology = '3111') and adenocarcinoma
  (Topography = '0401') cases
----------------------------------------------------------------*/
WITH
/* 1. Cohort of interest ---------------------------------------*/
cohort AS (
  SELECT DISTINCT
         RefNo,
         CaseNo,
         CONCAT(CAST(RefNo AS STRING),'::',CaseNo) AS sample_id
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  Morph = '3111'        -- breast cancer
     OR  Topo  = '0401'        -- adenocarcinoma
),

tot_cases AS (                 -- total number of cases
  SELECT COUNT(DISTINCT sample_id) AS n_cases
  FROM   cohort
),

/* 2. CytoConverter events for those cases ---------------------*/
events AS (
  SELECT
      c.RefNo,
      c.CaseNo,
      CONCAT(CAST(c.RefNo AS STRING),'::',c.CaseNo) AS sample_id,
      c.Chr   AS chr,
      c.Start AS evt_start,
      c.End   AS evt_end,
      LOWER(c.Type) AS type_lc
  FROM  `mitelman-db.prod.CytoConverted` c
  JOIN  cohort USING (RefNo, CaseNo)
),

/* 3. Overlap each event with cytobands and categorize ---------*/
events_in_band AS (
  SELECT *
  FROM (
    SELECT
        b.chromosome,
        b.cytoband_name,
        e.sample_id,
        CASE
          WHEN REGEXP_CONTAINS(e.type_lc , r'(amp|amplification|gain[+]?[>]?1|highgain)') THEN 'Amplification'
          WHEN e.type_lc = 'gain'                                             THEN 'Gain'
          WHEN REGEXP_CONTAINS(e.type_lc , r'(homdel|homozygous[_ ]?del|hd)') THEN 'HomoDel'
          WHEN REGEXP_CONTAINS(e.type_lc , r'(loss|deletion|del)')            THEN 'Loss'
        END AS cat
    FROM   events e
    JOIN   `mitelman-db.prod.CytoBands_hg38` b
           ON  b.chromosome = e.chr
           AND b.hg38_start < e.evt_end     -- overlap test
           AND b.hg38_stop  > e.evt_start
  )
  WHERE cat IS NOT NULL
),

/* 4. Counts per band ------------------------------------------*/
band_agg AS (
  SELECT
      chromosome,
      cytoband_name,
      COUNT(DISTINCT IF(cat = 'Amplification', sample_id, NULL)) AS ampl_cnt,
      COUNT(DISTINCT IF(cat = 'Gain'         , sample_id, NULL)) AS gain_cnt,
      COUNT(DISTINCT IF(cat = 'Loss'         , sample_id, NULL)) AS loss_cnt,
      COUNT(DISTINCT IF(cat = 'HomoDel'      , sample_id, NULL)) AS homdel_cnt
  FROM  events_in_band
  GROUP BY chromosome, cytoband_name
)

/* 5. Merge with band coordinates and compute percentages ------*/
SELECT
    b.chromosome,
    b.cytoband_name                                       AS band,
    b.hg38_start,
    b.hg38_stop,

    IFNULL(a.ampl_cnt ,0)                                 AS amplifications,
    ROUND(IFNULL(a.ampl_cnt ,0) / t.n_cases * 100, 2)     AS ampl_pct,

    IFNULL(a.gain_cnt  ,0)                                AS gains,
    ROUND(IFNULL(a.gain_cnt  ,0) / t.n_cases * 100, 2)    AS gain_pct,

    IFNULL(a.loss_cnt  ,0)                                AS losses,
    ROUND(IFNULL(a.loss_cnt  ,0) / t.n_cases * 100, 2)    AS loss_pct,

    IFNULL(a.homdel_cnt,0)                                AS homozygous_deletions,
    ROUND(IFNULL(a.homdel_cnt,0) / t.n_cases * 100, 2)    AS homdel_pct
FROM   `mitelman-db.prod.CytoBands_hg38` b
LEFT JOIN band_agg a USING (chromosome, cytoband_name)
CROSS JOIN tot_cases t
ORDER BY
  CASE
    WHEN b.chromosome = 'chrX' THEN 23
    WHEN b.chromosome = 'chrY' THEN 24
    ELSE SAFE_CAST(REGEXP_REPLACE(b.chromosome, r'chr', '') AS INT64)
  END,
  b.hg38_start,
  b.hg38_stop;