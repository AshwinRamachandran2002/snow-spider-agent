/* ------------------------------------------------------------
   Clones that simultaneously show
     1) Loss  chr13 : 48,303,751 – 48,481,890
     2) Loss  chr17 :  7,668,421 –  7,687,490
     3) Gain  chr11 :108,223,067 –108,369,102

   Output: reference, case, investigation, clone number,
           chromosomal details for the three regions
           plus the corresponding karyotype short description
-------------------------------------------------------------*/
WITH
/* ---- chr13 loss ------------------------------------------- */
chr13_raw AS (
  SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY `Start`, `End`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND `Start` <= 48481890      -- region overlap test
    AND `End`   >= 48303751
),
chr13 AS (
  SELECT RefNo, CaseNo, InvNo, Clone, ChrOrd, `Start`, `End`
  FROM chr13_raw
  WHERE rn = 1
),

/* ---- chr17 loss ------------------------------------------- */
chr17_raw AS (
  SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY `Start`, `End`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND `Start` <= 7687490
    AND `End`   >= 7668421
),
chr17 AS (
  SELECT RefNo, CaseNo, InvNo, Clone, ChrOrd, `Start`, `End`
  FROM chr17_raw
  WHERE rn = 1
),

/* ---- chr11 gain ------------------------------------------- */
chr11_raw AS (
  SELECT
      RefNo, CaseNo, InvNo, Clone,
      ChrOrd, `Start`, `End`,
      ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone
                         ORDER BY `Start`, `End`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND `Start` <= 108369102
    AND `End`   >= 108223067
),
chr11 AS (
  SELECT RefNo, CaseNo, InvNo, Clone, ChrOrd, `Start`, `End`
  FROM chr11_raw
  WHERE rn = 1
)

/* ---- combine the three conditions and attach karyotype ----- */
SELECT
    c13.RefNo,
    c13.CaseNo,
    c13.InvNo,
    c13.Clone        AS CloneNo,

    /* chr13 (loss) */
    c13.ChrOrd       AS Chr13_ChrOrd,
    c13.Start        AS Chr13_Start,
    c13.End          AS Chr13_End,

    /* chr17 (loss) */
    c17.ChrOrd       AS Chr17_ChrOrd,
    c17.Start        AS Chr17_Start,
    c17.End          AS Chr17_End,

    /* chr11 (gain) */
    c11.ChrOrd       AS Chr11_ChrOrd,
    c11.Start        AS Chr11_Start,
    c11.End          AS Chr11_End,

    /* karyotype short description */
    k.CloneShort
FROM chr13  c13
JOIN chr17  c17 USING (RefNo, CaseNo, InvNo, Clone)
JOIN chr11  c11 USING (RefNo, CaseNo, InvNo, Clone)
JOIN `mitelman-db.prod.KaryClone` k
  ON k.RefNo   = c13.RefNo
 AND k.CaseNo  = c13.CaseNo
 AND k.InvNo   = c13.InvNo
 AND k.CloneNo = c13.Clone
ORDER BY RefNo, CaseNo, InvNo, CloneNo;