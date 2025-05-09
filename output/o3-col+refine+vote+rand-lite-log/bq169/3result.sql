/*  Clones that simultaneously show
    – Loss on chr13 (48 303 751-48 481 890)
    – Loss on chr17 ( 7 668 421- 7 687 490)
    – Gain on chr11 (108 223 067-108 369 102)
    together with their karyotype description                         */

WITH
/* ---- loss on 13q14 region --------------------------------------- */
loss13 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    MIN(`Start`) AS Start_13,
    MAX(`End`)   AS End_13          -- collapse to one segment per clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND `Start` <= 48303751
    AND `End`   >= 48481890
  GROUP BY RefNo, CaseNo, InvNo, Clone
),
/* ---- loss on 17p13 region --------------------------------------- */
loss17 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    MIN(`Start`) AS Start_17,
    MAX(`End`)   AS End_17
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND `Start` <=  7668421
    AND `End`   >=  7687490
  GROUP BY RefNo, CaseNo, InvNo, Clone
),
/* ---- gain on 11q23 region --------------------------------------- */
gain11 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    MIN(`Start`) AS Start_11,
    MAX(`End`)   AS End_11
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND `Start` <= 108223067
    AND `End`   >= 108369102
  GROUP BY RefNo, CaseNo, InvNo, Clone
)

/* ---- bring the three events together ---------------------------- */
SELECT DISTINCT
  l13.RefNo,
  l13.CaseNo,
  l13.InvNo,
  l13.Clone            AS CloneNo,
  kc.CloneShort,       -- karyotype description (if available)

  11 AS ChrOrd_11,
  g11.Start_11,
  g11.End_11,

  13 AS ChrOrd_13,
  l13.Start_13,
  l13.End_13,

  17 AS ChrOrd_17,
  l17.Start_17,
  l17.End_17
FROM loss13 AS l13
JOIN loss17 AS l17 USING (RefNo, CaseNo, InvNo, Clone)
JOIN gain11 AS g11 USING (RefNo, CaseNo, InvNo, Clone)
LEFT JOIN `mitelman-db.prod.KaryClone` AS kc
  ON kc.RefNo   = l13.RefNo
 AND kc.CaseNo  = l13.CaseNo
 AND kc.InvNo   = l13.InvNo
 AND kc.CloneNo = l13.Clone
ORDER BY RefNo, CaseNo, InvNo, CloneNo;