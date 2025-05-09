/*  Retrieve clones that harbour ALL THREE aberrations  
    1) chr13 Loss 48 303 751–48 481 890  
    2) chr17 Loss  7 668 421–7 687 490  
    3) chr11 Gain 108 223 067–108 369 102
*/
WITH
-- chr13 loss
chr13 AS (
  SELECT DISTINCT RefNo, CaseNo, InvNo, Clone,
         ChrOrd AS Chr13_ChrOrd,
         Start  AS Chr13_Start,
         `End`  AS Chr13_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr13'
    AND Type = 'Loss'
    AND Start <= 48481890      -- region max
    AND `End` >= 48303751      -- region min
),
-- chr17 loss
chr17 AS (
  SELECT DISTINCT RefNo, CaseNo, InvNo, Clone,
         ChrOrd AS Chr17_ChrOrd,
         Start  AS Chr17_Start,
         `End`  AS Chr17_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr17'
    AND Type = 'Loss'
    AND Start <= 7687490       -- region max
    AND `End` >= 7668421       -- region min
),
-- chr11 gain
chr11 AS (
  SELECT DISTINCT RefNo, CaseNo, InvNo, Clone,
         ChrOrd AS Chr11_ChrOrd,
         Start  AS Chr11_Start,
         `End`  AS Chr11_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr11'
    AND Type = 'Gain'
    AND Start <= 108369102     -- region max
    AND `End`  >= 108223067    -- region min
),

-- clones that have all three events
hits AS (
  SELECT c13.RefNo, c13.CaseNo, c13.InvNo, c13.Clone
  FROM chr13 c13
  JOIN chr17 USING (RefNo, CaseNo, InvNo, Clone)
  JOIN chr11 USING (RefNo, CaseNo, InvNo, Clone)
)

SELECT DISTINCT
  h.RefNo,
  h.CaseNo,
  h.InvNo,
  h.Clone,

  c13.Chr13_ChrOrd,
  c13.Chr13_Start,
  c13.Chr13_End,

  c17.Chr17_ChrOrd,
  c17.Chr17_Start,
  c17.Chr17_End,

  c11.Chr11_ChrOrd,
  c11.Chr11_Start,
  c11.Chr11_End,

  k.CloneShort AS KaryotypeShort
FROM hits h
JOIN chr13 c13 USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr17 c17 USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr11 c11 USING (RefNo, CaseNo, InvNo, Clone)
LEFT JOIN `mitelman-db.prod.KaryClone` k
       ON k.RefNo   = h.RefNo
      AND k.CaseNo  = h.CaseNo
      AND k.InvNo   = h.InvNo
      AND k.CloneNo = h.Clone
ORDER BY h.RefNo, h.CaseNo, h.InvNo, h.Clone;