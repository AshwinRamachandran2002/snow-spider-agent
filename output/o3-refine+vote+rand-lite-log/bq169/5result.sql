/* clones that have all three specified alterations ----------------------- */
WITH
/* 1. loss on chromosome 13 (48,303,751‑48,481,890) */
chr13_loss AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    13            AS ChrOrd,
    MIN(Start)    AS RegionStart,
    MAX(`End`)    AS RegionEnd
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND Start <= 48303751          -- region start
    AND `End` >= 48481890          -- region end
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

/* 2. loss on chromosome 17 (7,668,421‑7,687,490) */
chr17_loss AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    17            AS ChrOrd,
    MIN(Start)    AS RegionStart,
    MAX(`End`)    AS RegionEnd
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND Start <=  7668421
    AND `End` >=  7687490
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

/* 3. gain on chromosome 11 (108,223,067‑108,369,102) */
chr11_gain AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    11            AS ChrOrd,
    MIN(Start)    AS RegionStart,
    MAX(`End`)    AS RegionEnd
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND Start <= 108223067
    AND `End` >= 108369102
  GROUP BY RefNo, CaseNo, InvNo, Clone
)

/* ----------------------------------------------------------------------- */
SELECT
  c13.RefNo,
  c13.CaseNo,
  c13.InvNo,
  c13.Clone                      AS CloneNo,

  /* details for each requested region */
  c13.ChrOrd                     AS Chr13_ChrOrd,
  c13.RegionStart                AS Chr13_Start,
  c13.RegionEnd                  AS Chr13_End,

  c17.ChrOrd                     AS Chr17_ChrOrd,
  c17.RegionStart                AS Chr17_Start,
  c17.RegionEnd                  AS Chr17_End,

  c11.ChrOrd                     AS Chr11_ChrOrd,
  c11.RegionStart                AS Chr11_Start,
  c11.RegionEnd                  AS Chr11_End,

  kc.CloneShort                  AS KaryotypeShort
FROM chr13_loss AS c13
JOIN chr17_loss AS c17
  USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr11_gain AS c11
  USING (RefNo, CaseNo, InvNo, Clone)
LEFT JOIN `mitelman-db.prod.KaryClone` AS kc
  ON  kc.RefNo   = c13.RefNo
  AND kc.CaseNo  = c13.CaseNo
  AND kc.InvNo   = c13.InvNo
  AND kc.CloneNo = c13.Clone
ORDER BY RefNo, CaseNo, InvNo, CloneNo;