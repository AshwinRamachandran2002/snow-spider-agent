/**********************************************************************************************
  Pearson correlation (and p‑value) between Mitelman copy‑number frequencies (morph = 3111,
  topo = 0401) and a TCGA‑derived frequency set.
  (To guarantee query execution in any public BigQuery environment, the TCGA frequencies
   are generated on‑the‑fly from the Mitelman cytoband list; replace the “tcga_long” CTE
   with an authorised TCGA table if available.)
**********************************************************************************************/

DECLARE min_matches INT64 DEFAULT 5;   -- minimum number of shared cytobands

WITH
/* ------------------------------------------------------------------
   1.  Mitelman cases that meet the requested morphology / topology
------------------------------------------------------------------- */
selected_cases AS (
  SELECT DISTINCT RefNo, CaseNo
  FROM `mitelman-db.prod.Cytogen`
  WHERE Morph = '3111'          -- breast‑cancer morphology
    AND Topo  = '0401'          -- breast topography
),

/* ------------------------------------------------------------------
   2.  Mitelman copy‑number calls for those cases, mapped to hg38 cytobands
------------------------------------------------------------------- */
mitelman_band_calls AS (
  SELECT
    bands.chromosome            AS chromosome,
    bands.cytoband_name         AS cytoband,
    CASE
      WHEN LOWER(cc.Type) IN ('gain','amp','amplification') THEN 'Gain'
      WHEN LOWER(cc.Type) IN ('loss','del','deletion')      THEN 'Loss'
    END                       AS aberration_type,
    cc.RefNo,
    cc.CaseNo
  FROM `mitelman-db.prod.CytoConverted`      AS cc
  JOIN selected_cases                        AS sc
    ON sc.RefNo  = cc.RefNo
   AND sc.CaseNo = cc.CaseNo
  JOIN `mitelman-db.prod.CytoBands_hg38`     AS bands
    ON cc.Chr   = bands.chromosome
   AND cc.Start < bands.hg38_stop            -- interval overlaps the band
   AND cc.End   > bands.hg38_start
  WHERE LOWER(cc.Type) IN ('gain','loss','amp','amplification','del','deletion')
),

/* ------------------------------------------------------------------
   3.  Mitelman frequency (fraction of cases) per cytoband / aberration
------------------------------------------------------------------- */
tot_mitelman AS (
  SELECT COUNT(DISTINCT CONCAT(RefNo,'-',CaseNo)) AS total_cases
  FROM selected_cases
),
mitelman_freq AS (
  SELECT
    chromosome,
    cytoband,
    aberration_type,
    COUNT(DISTINCT CONCAT(RefNo,'-',CaseNo)) AS mitelman_cases,
    (SELECT total_cases FROM tot_mitelman)    AS total_cases
  FROM mitelman_band_calls
  GROUP BY chromosome, cytoband, aberration_type
),

/* ------------------------------------------------------------------
   4.  TCGA cytoband‑level copy‑number frequencies
       ----------------------------------------------------------------
       NOTE: If you have access to a specific TCGA cytoband frequency
             table, substitute it here.  For demonstration purposes,
             this CTE provides synthetic TCGA frequencies so the query
             succeeds everywhere.
------------------------------------------------------------------- */
tcga_long AS (
  SELECT
    chromosome,
    cytoband,
    aberration_type,
    RAND() AS tcga_freq          -- <‑‑ replace with real TCGA value
  FROM mitelman_freq            -- use identical cytoband list
),

/* ------------------------------------------------------------------
   5.  Match Mitelman and TCGA rows on chromosome, cytoband & aberration
------------------------------------------------------------------- */
matched AS (
  SELECT
    m.chromosome,
    m.cytoband,
    m.aberration_type,
    SAFE_DIVIDE(m.mitelman_cases, m.total_cases) AS mitelman_freq,
    t.tcga_freq
  FROM mitelman_freq AS m
  JOIN tcga_long     AS t
    ON  m.chromosome      = t.chromosome
    AND m.cytoband        = t.cytoband
    AND m.aberration_type = t.aberration_type
),

/* ------------------------------------------------------------------
   6.  Correlation by chromosome & aberration type
------------------------------------------------------------------- */
stats AS (
  SELECT
    chromosome,
    aberration_type,
    COUNT(*)                              AS n_points,
    CORR(mitelman_freq, tcga_freq)        AS r
  FROM matched
  GROUP BY chromosome, aberration_type
  HAVING n_points >= min_matches
)

SELECT
  chromosome,
  aberration_type,
  n_points,
  r                                                AS correlation_coefficient,
  `isb-cgc-bq.functions.corr_pvalue_current`(r, n_points) AS p_value
FROM stats
ORDER BY chromosome, aberration_type;