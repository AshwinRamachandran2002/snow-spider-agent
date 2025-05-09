WITH
-- clones that carry the chr 13 loss (48 303 751 – 48 481 890)
region13 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ANY_VALUE(ChrOrd)   AS Chr13_ChrOrd,
    MIN(`Start`)        AS Chr13_Loss_Start,
    MAX(`End`)          AS Chr13_Loss_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
        ChrOrd = 13
    AND Type  = 'Loss'
    AND `Start` <= 48481890          -- segment starts before / at region end
    AND `End`   >= 48303751          -- segment ends   after / at region start
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- clones that carry the chr 17 loss (7 668 421 – 7 687 490)
region17 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ANY_VALUE(ChrOrd)   AS Chr17_ChrOrd,
    MIN(`Start`)        AS Chr17_Loss_Start,
    MAX(`End`)          AS Chr17_Loss_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
        ChrOrd = 17
    AND Type  = 'Loss'
    AND `Start` <= 7687490
    AND `End`   >= 7668421
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- clones that carry the chr 11 gain (108 223 067 – 108 369 102)
region11 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ANY_VALUE(ChrOrd)   AS Chr11_ChrOrd,
    MIN(`Start`)        AS Chr11_Gain_Start,
    MAX(`End`)          AS Chr11_Gain_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
        ChrOrd = 11
    AND Type  = 'Gain'
    AND `Start` <= 108369102
    AND `End`   >= 108223067
  GROUP BY RefNo, CaseNo, InvNo, Clone
)

SELECT DISTINCT
  r13.RefNo,
  r13.CaseNo,
  r13.InvNo,
  r13.Clone                    AS CloneNo,
  kc.CloneShort                AS Karyotype_Short,

  -- chromosomal details for each required region
  r13.Chr13_ChrOrd             AS Chr13_Ord,
  r13.Chr13_Loss_Start,
  r13.Chr13_Loss_End,

  r17.Chr17_ChrOrd             AS Chr17_Ord,
  r17.Chr17_Loss_Start,
  r17.Chr17_Loss_End,

  r11.Chr11_ChrOrd             AS Chr11_Ord,
  r11.Chr11_Gain_Start,
  r11.Chr11_Gain_End
FROM region13 r13
JOIN region17 r17 USING (RefNo, CaseNo, InvNo, Clone)
JOIN region11 r11 USING (RefNo, CaseNo, InvNo, Clone)
LEFT JOIN `mitelman-db.prod.KaryClone` kc
       ON kc.RefNo   = r13.RefNo
      AND kc.CaseNo  = r13.CaseNo
      AND kc.InvNo   = r13.InvNo
      AND kc.CloneNo = r13.Clone
ORDER BY RefNo, CaseNo, InvNo, CloneNo;