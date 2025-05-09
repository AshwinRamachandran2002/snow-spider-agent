-- ====================================================================
--  Frequency of copy‑number changes per cytogenetic band
--  Cohort : Breast cancer (Morph = 3111) AND Adenocarcinoma (Topo = 0401)
-- ====================================================================

WITH
/* ---------------------------------------------------------------
   1.  Cohort definition  (one row per Case = RefNo + CaseNo)
-----------------------------------------------------------------*/
cohort_cases AS (
  SELECT DISTINCT RefNo , CaseNo
  FROM   `mitelman-db.prod.Cytogen`
  WHERE  Morph = '3111'        -- breast cancer
    AND  Topo  = '0401'        -- adenocarcinoma
),
/* ---------------------------------------------------------------
   2.  Copy‑number events for the cohort
-----------------------------------------------------------------*/
events AS (
  SELECT cc.RefNo ,
         cc.CaseNo ,
         cc.Chr        AS chromosome ,
         cc.Start      AS evt_start ,
         cc.End        AS evt_end ,
         COALESCE(cc.Type,'') AS raw_type
  FROM   `mitelman-db.prod.CytoConverted` cc
  JOIN   cohort_cases c
         ON cc.RefNo = c.RefNo
        AND cc.CaseNo = c.CaseNo
),
/* ---------------------------------------------------------------
   3.  Categorise each event
-----------------------------------------------------------------*/
events_categorised AS (
  SELECT RefNo ,
         CaseNo ,
         chromosome ,
         evt_start ,
         evt_end ,
         CASE
           WHEN LOWER(raw_type) LIKE '%amp%'                       THEN 'Amplification'
           WHEN LOWER(raw_type) LIKE '%hom%'  OR
                LOWER(raw_type) LIKE '%deep%'                      THEN 'HomozygousDeletion'
           WHEN LOWER(raw_type) LIKE '%loss%'                      THEN 'Loss'
           WHEN LOWER(raw_type) LIKE '%gain%'                      THEN 'Gain'
           ELSE 'Other'
         END                                                       AS evt_cat
  FROM   events
),
/* ---------------------------------------------------------------
   4.  Overlap every event with cytogenetic bands (hg38)
-----------------------------------------------------------------*/
event_band AS (
  SELECT DISTINCT
         e.RefNo ,
         e.CaseNo ,
         e.evt_cat ,
         b.chromosome ,
         b.cytoband_name ,
         b.hg38_start ,
         b.hg38_stop
  FROM   events_categorised   e
  JOIN   `mitelman-db.prod.CytoBands_hg38` b
         ON  b.chromosome = e.chromosome
         AND e.evt_end   > b.hg38_start      -- overlap test
         AND e.evt_start < b.hg38_stop
  WHERE  e.evt_cat IN ('Amplification','Gain','Loss','HomozygousDeletion')
),
/* ---------------------------------------------------------------
   5.  Counts per band (one count per case to avoid double counting)
-----------------------------------------------------------------*/
band_counts AS (
  SELECT
    chromosome ,
    cytoband_name ,
    hg38_start ,
    hg38_stop ,
    COUNT(DISTINCT CASE WHEN evt_cat = 'Amplification'      THEN CONCAT(RefNo,'_',CaseNo) END) AS n_amp ,
    COUNT(DISTINCT CASE WHEN evt_cat = 'Gain'               THEN CONCAT(RefNo,'_',CaseNo) END) AS n_gain ,
    COUNT(DISTINCT CASE WHEN evt_cat = 'Loss'               THEN CONCAT(RefNo,'_',CaseNo) END) AS n_loss ,
    COUNT(DISTINCT CASE WHEN evt_cat = 'HomozygousDeletion' THEN CONCAT(RefNo,'_',CaseNo) END) AS n_homdel
  FROM   event_band
  GROUP  BY chromosome , cytoband_name , hg38_start , hg38_stop
),
/* ---------------------------------------------------------------
   6.  Total number of cases in the cohort
-----------------------------------------------------------------*/
tot AS (
  SELECT COUNT(DISTINCT CONCAT(RefNo,'_',CaseNo)) AS total_cases
  FROM   cohort_cases
)
/* ---------------------------------------------------------------
   7.  Final report with percentages
-----------------------------------------------------------------*/
SELECT
  bc.chromosome ,
  bc.cytoband_name ,
  bc.hg38_start ,
  bc.hg38_stop ,
  bc.n_amp        AS amplifications ,
  ROUND( 100 * bc.n_amp    / tot.total_cases , 2 ) AS amplification_pct ,
  bc.n_gain       AS gains ,
  ROUND( 100 * bc.n_gain   / tot.total_cases , 2 ) AS gain_pct ,
  bc.n_loss       AS losses ,
  ROUND( 100 * bc.n_loss   / tot.total_cases , 2 ) AS loss_pct ,
  bc.n_homdel     AS homozygous_deletions ,
  ROUND( 100 * bc.n_homdel / tot.total_cases , 2 ) AS homdel_pct
FROM   band_counts bc
CROSS  JOIN tot
ORDER  BY
  -- numerical chromosome order 1‑22, X=23, Y=24
  CASE
    WHEN bc.chromosome = 'chrX' THEN 23
    WHEN bc.chromosome = 'chrY' THEN 24
    ELSE CAST(REGEXP_REPLACE(bc.chromosome, r'^chr','') AS INT64)
  END ,
  bc.hg38_start ;