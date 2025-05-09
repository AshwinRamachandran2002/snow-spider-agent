/*  Retrieve clones that harbour
    1) 13q loss   (48 303 751–48 481 890)
    2) 17p loss   (7 668 421–7 687 490)
    3) 11q gain   (108 223 067–108 369 102)

    For every qualifying (RefNo, CaseNo, InvNo, Clone) report the
    coordinates of the three alterations plus the karyotype
    description from KaryClone.
*/

WITH
-- 13q loss
loss13 AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    MIN(`Start`) AS start_13,
    MAX(`End`)   AS end_13
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND `Start` < 48481890         -- region overlaps 48 303 751–48 481 890
    AND `End`   > 48303751
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- 17p loss
loss17 AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    MIN(`Start`) AS start_17,
    MAX(`End`)   AS end_17
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND `Start` < 7687490          -- region overlaps 7 668 421–7 687 490
    AND `End`   > 7668421
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- 11q gain
gain11 AS (
  SELECT
    RefNo, CaseNo, InvNo, Clone,
    MIN(`Start`) AS start_11,
    MAX(`End`)   AS end_11
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND `Start` < 108369102        -- region overlaps 108 223 067–108 369 102
    AND `End`   > 108223067
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- clones possessing all three alterations
triples AS (
  SELECT
    l13.RefNo, l13.CaseNo, l13.InvNo, l13.Clone,
    13 AS chrord_13, l13.start_13, l13.end_13,
    17 AS chrord_17, l17.start_17, l17.end_17,
    11 AS chrord_11, g11.start_11, g11.end_11
  FROM loss13 l13
  JOIN loss17 l17 USING (RefNo, CaseNo, InvNo, Clone)
  JOIN gain11 g11 USING (RefNo, CaseNo, InvNo, Clone)
)

SELECT
  t.RefNo,
  t.CaseNo,
  t.InvNo,
  t.Clone,
  t.chrord_13 AS ChrOrd_13,
  t.start_13  AS Start_13,
  t.end_13    AS End_13,
  t.chrord_17 AS ChrOrd_17,
  t.start_17  AS Start_17,
  t.end_17    AS End_17,
  t.chrord_11 AS ChrOrd_11,
  t.start_11  AS Start_11,
  t.end_11    AS End_11,
  kc.CloneShort AS Karyotype
FROM triples AS t
LEFT JOIN `mitelman-db.prod.KaryClone` AS kc
  ON  kc.RefNo   = t.RefNo
  AND kc.CaseNo  = t.CaseNo
  AND kc.InvNo   = t.InvNo
  AND kc.CloneNo = t.Clone
ORDER BY t.RefNo, t.CaseNo, t.InvNo, t.Clone;