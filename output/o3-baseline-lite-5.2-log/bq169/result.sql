WITH clone_regions AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone,

    /* -------- loss on chr13 (48 303 751 – 48 481 890) -------- */
    MAX(IF(ChrOrd = 13
           AND Type = 'Loss'
           AND `Start` <= 48303751            -- region begins at or before lower bound
           AND `End`   >= 48481890,           -- region ends   at or after upper bound
           ChrOrd, NULL)) AS Chr13_ChrOrd,
    MIN(IF(ChrOrd = 13
           AND Type = 'Loss'
           AND `Start` <= 48303751
           AND `End`   >= 48481890,
           `Start`, NULL))                   AS Chr13_Start,
    MAX(IF(ChrOrd = 13
           AND Type = 'Loss'
           AND `Start` <= 48303751
           AND `End`   >= 48481890,
           `End`,   NULL))                   AS Chr13_End,

    /* -------- loss on chr17 (7 668 421 – 7 687 490) -------- */
    MAX(IF(ChrOrd = 17
           AND Type = 'Loss'
           AND `Start` <=  7668421
           AND `End`   >=  7687490,
           ChrOrd, NULL)) AS Chr17_ChrOrd,
    MIN(IF(ChrOrd = 17
           AND Type = 'Loss'
           AND `Start` <=  7668421
           AND `End`   >=  7687490,
           `Start`, NULL))                   AS Chr17_Start,
    MAX(IF(ChrOrd = 17
           AND Type = 'Loss'
           AND `Start` <=  7668421
           AND `End`   >=  7687490,
           `End`,   NULL))                   AS Chr17_End,

    /* -------- gain on chr11 (108 223 067 – 108 369 102) -------- */
    MAX(IF(ChrOrd = 11
           AND Type = 'Gain'
           AND `Start` <= 108223067
           AND `End`   >= 108369102,
           ChrOrd, NULL)) AS Chr11_ChrOrd,
    MIN(IF(ChrOrd = 11
           AND Type = 'Gain'
           AND `Start` <= 108223067
           AND `End`   >= 108369102,
           `Start`, NULL))                   AS Chr11_Start,
    MAX(IF(ChrOrd = 11
           AND Type = 'Gain'
           AND `Start` <= 108223067
           AND `End`   >= 108369102,
           `End`,   NULL))                   AS Chr11_End

  FROM `mitelman-db.prod.CytoConverted`
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

qualified_clones AS (
  SELECT *
  FROM clone_regions
  WHERE Chr13_ChrOrd IS NOT NULL
    AND Chr17_ChrOrd IS NOT NULL
    AND Chr11_ChrOrd IS NOT NULL            -- clone shows ALL three alterations
)

SELECT
  qc.RefNo,
  qc.CaseNo,
  qc.InvNo,
  qc.Clone         AS CloneNo,

  /* chr13 loss details */
  qc.Chr13_ChrOrd  AS Chr13_ChrOrd,
  qc.Chr13_Start   AS Chr13_Start,
  qc.Chr13_End     AS Chr13_End,

  /* chr17 loss details */
  qc.Chr17_ChrOrd  AS Chr17_ChrOrd,
  qc.Chr17_Start   AS Chr17_Start,
  qc.Chr17_End     AS Chr17_End,

  /* chr11 gain details */
  qc.Chr11_ChrOrd  AS Chr11_ChrOrd,
  qc.Chr11_Start   AS Chr11_Start,
  qc.Chr11_End     AS Chr11_End,

  kc.CloneShort    -- corresponding karyotype description
FROM qualified_clones   qc
LEFT JOIN `mitelman-db.prod.KaryClone` kc
       ON qc.RefNo   = kc.RefNo
      AND qc.CaseNo  = kc.CaseNo
      AND qc.InvNo   = kc.InvNo
      AND qc.Clone   = kc.CloneNo
ORDER BY
  qc.RefNo,
  qc.CaseNo,
  qc.InvNo,
  qc.Clone;