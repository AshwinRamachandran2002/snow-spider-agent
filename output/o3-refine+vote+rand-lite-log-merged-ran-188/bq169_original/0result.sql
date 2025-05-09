WITH
/* 1. clones that show a LOSS on chr 13 covering 48 303 751‑48 481 890 */
chr13_loss AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`,
    ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone ORDER BY `Start`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
    Type   = 'Loss'
    AND ChrOrd = 13
    AND `Start` <= 48303751
    AND `End`   >= 48481890
),

/* 2. clones that show a LOSS on chr 17 covering 7 668 421‑7 687 490 */
chr17_loss AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`,
    ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone ORDER BY `Start`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
    Type   = 'Loss'
    AND ChrOrd = 17
    AND `Start` <=  7668421
    AND `End`   >=  7687490
),

/* 3. clones that show a GAIN on chr 11 covering 108 223 067‑108 369 102 */
chr11_gain AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,
    ChrOrd,
    `Start`,
    `End`,
    ROW_NUMBER() OVER (PARTITION BY RefNo, CaseNo, InvNo, Clone ORDER BY `Start`) AS rn
  FROM `mitelman-db.prod.CytoConverted`
  WHERE
    Type   = 'Gain'
    AND ChrOrd = 11
    AND `Start` <= 108223067
    AND `End`   >= 108369102
)

SELECT DISTINCT
  c13.RefNo,
  c13.CaseNo,
  c13.InvNo,
  c13.Clone                          AS CloneNo,

  /* chr 13 loss details */
  c13.ChrOrd                         AS Chr13_ChrOrd,
  c13.`Start`                        AS Chr13_Start,
  c13.`End`                          AS Chr13_End,

  /* chr 17 loss details */
  c17.ChrOrd                         AS Chr17_ChrOrd,
  c17.`Start`                        AS Chr17_Start,
  c17.`End`                          AS Chr17_End,

  /* chr 11 gain details */
  c11.ChrOrd                         AS Chr11_ChrOrd,
  c11.`Start`                        AS Chr11_Start,
  c11.`End`                          AS Chr11_End,

  kc.CloneShort                      AS KaryShort
FROM chr13_loss c13
JOIN chr17_loss c17
  ON c13.RefNo   = c17.RefNo
 AND c13.CaseNo  = c17.CaseNo
 AND c13.InvNo   = c17.InvNo
 AND c13.Clone   = c17.Clone
JOIN chr11_gain c11
  ON c13.RefNo   = c11.RefNo
 AND c13.CaseNo  = c11.CaseNo
 AND c13.InvNo   = c11.InvNo
 AND c13.Clone   = c11.Clone
LEFT JOIN `mitelman-db.prod.KaryClone` kc
  ON kc.RefNo    = c13.RefNo
 AND kc.CaseNo   = c13.CaseNo
 AND kc.InvNo    = c13.InvNo
 AND kc.CloneNo  = c13.Clone
WHERE
  c13.rn = 1
  AND c17.rn = 1
  AND c11.rn = 1
ORDER BY
  RefNo,
  CaseNo,
  InvNo,
  CloneNo;