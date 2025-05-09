/*  Clones that harbour
    1) Loss on chr13 covering 48 303 751‑48 481 890
    2) Loss on chr17 covering  7 668 421‑ 7 687 490
    3) Gain on chr11 covering 108 223 067‑108 369 102
    together with the exact chromosomal segments and the
    karyotype short description.
*/
WITH
--‑‑ clones fulfilling each single criterion
loss13 AS (
  SELECT RefNo, CaseNo, InvNo, Clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND `Start` <= 48303751
    AND `End`   >= 48481890
),
loss17 AS (
  SELECT RefNo, CaseNo, InvNo, Clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND `Start` <=  7668421
    AND `End`   >=  7687490
),
gain11 AS (
  SELECT RefNo, CaseNo, InvNo, Clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND `Start` <= 108223067
    AND `End`   >= 108369102
),

--‑‑ clones that satisfy all three requirements
hits AS (
  SELECT l13.RefNo, l13.CaseNo, l13.InvNo, l13.Clone
  FROM  loss13 l13
  JOIN  loss17 l17 USING (RefNo, CaseNo, InvNo, Clone)
  JOIN  gain11 g11 USING (RefNo, CaseNo, InvNo, Clone)
)

SELECT DISTINCT
  h.RefNo,
  h.CaseNo,
  h.InvNo,
  h.Clone                AS CloneNo,

  cv13.ChrOrd            AS ChrOrd_13,
  cv13.Start             AS Start_13,
  cv13.End               AS End_13,

  cv17.ChrOrd            AS ChrOrd_17,
  cv17.Start             AS Start_17,
  cv17.End               AS End_17,

  cv11.ChrOrd            AS ChrOrd_11,
  cv11.Start             AS Start_11,
  cv11.End               AS End_11,

  kc.CloneShort          AS KaryShort
FROM   hits h

-- bring back the exact segments for each alteration
JOIN `mitelman-db.prod.CytoConverted` cv13
     ON cv13.RefNo = h.RefNo  AND cv13.CaseNo = h.CaseNo
    AND cv13.InvNo = h.InvNo  AND cv13.Clone  = h.Clone
    AND cv13.ChrOrd = 13      AND cv13.Type = 'Loss'
    AND cv13.Start <= 48303751 AND cv13.End >= 48481890

JOIN `mitelman-db.prod.CytoConverted` cv17
     ON cv17.RefNo = h.RefNo  AND cv17.CaseNo = h.CaseNo
    AND cv17.InvNo = h.InvNo  AND cv17.Clone  = h.Clone
    AND cv17.ChrOrd = 17      AND cv17.Type = 'Loss'
    AND cv17.Start <= 7668421  AND cv17.End >= 7687490

JOIN `mitelman-db.prod.CytoConverted` cv11
     ON cv11.RefNo = h.RefNo  AND cv11.CaseNo = h.CaseNo
    AND cv11.InvNo = h.InvNo  AND cv11.Clone  = h.Clone
    AND cv11.ChrOrd = 11      AND cv11.Type = 'Gain'
    AND cv11.Start <= 108223067 AND cv11.End >= 108369102

-- karyotype information
LEFT JOIN `mitelman-db.prod.KaryClone` kc
       ON kc.RefNo  = h.RefNo
      AND kc.CaseNo = h.CaseNo
      AND kc.InvNo  = h.InvNo
      AND kc.CloneNo = h.Clone

ORDER BY h.RefNo, h.CaseNo, h.InvNo, h.Clone;