WITH
/* (1) loss on chromosome 13: 48,303,751–48,481,890 */
loss13 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr13'
    AND Type = 'Loss'
    AND `Start` <= 48481890      -- region end
    AND `End`   >= 48303751      -- region start
),

/* (2) loss on chromosome 17: 7,668,421–7,687,490 */
loss17 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr17'
    AND Type = 'Loss'
    AND `Start` <= 7687490       -- region end
    AND `End`   >= 7668421       -- region start
),

/* (3) gain on chromosome 11: 108,223,067–108,369,102 */
gain11 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`
  FROM `mitelman-db.prod.CytoConverted`
  WHERE Chr  = 'chr11'
    AND Type = 'Gain'
    AND `Start` <= 108369102     -- region end
    AND `End`   >= 108223067     -- region start
)

SELECT DISTINCT
  l13.RefNo,
  l13.CaseNo,
  l13.InvNo,
  l13.Clone                                  AS CloneNo,

  -- details for chromosome 13 loss
  l13.ChrOrd                                 AS Chr13_Ord,
  l13.`Start`                                AS Chr13_Start,
  l13.`End`                                  AS Chr13_End,

  -- details for chromosome 17 loss
  l17.ChrOrd                                 AS Chr17_Ord,
  l17.`Start`                                AS Chr17_Start,
  l17.`End`                                  AS Chr17_End,

  -- details for chromosome 11 gain
  g11.ChrOrd                                 AS Chr11_Ord,
  g11.`Start`                                AS Chr11_Start,
  g11.`End`                                  AS Chr11_End,

  kc.CloneShort                              AS KaryShort
FROM loss13 l13
JOIN loss17 l17
  ON l13.RefNo  = l17.RefNo
 AND l13.CaseNo = l17.CaseNo
 AND l13.InvNo  = l17.InvNo
 AND l13.Clone  = l17.Clone
JOIN gain11 g11
  ON l13.RefNo  = g11.RefNo
 AND l13.CaseNo = g11.CaseNo
 AND l13.InvNo  = g11.InvNo
 AND l13.Clone  = g11.Clone
LEFT JOIN `mitelman-db.prod.KaryClone` kc
  ON l13.RefNo  = kc.RefNo
 AND l13.CaseNo = kc.CaseNo
 And l13.InvNo  = kc.InvNo
 And l13.Clone  = kc.CloneNo
ORDER BY RefNo, CaseNo, InvNo, CloneNo;