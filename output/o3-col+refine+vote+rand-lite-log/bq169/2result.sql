SELECT DISTINCT
  c13.RefNo                          AS RefNo,
  c13.CaseNo                         AS CaseNo,
  c13.InvNo                          AS InvNo,
  c13.Clone                          AS CloneNo,

  -- chr-13 loss interval
  c13.ChrOrd                         AS Chr13_Ord,
  c13.Start                          AS Chr13_Start,
  c13.End                            AS Chr13_End,

  -- chr-17 loss interval
  c17.ChrOrd                         AS Chr17_Ord,
  c17.Start                          AS Chr17_Start,
  c17.End                            AS Chr17_End,

  -- chr-11 gain interval
  c11.ChrOrd                         AS Chr11_Ord,
  c11.Start                          AS Chr11_Start,
  c11.End                            AS Chr11_End,

  -- karyotype description
  kc.CloneShort                      AS CloneShort
FROM `mitelman-db.prod.CytoConverted` AS c13
JOIN `mitelman-db.prod.CytoConverted` AS c17
  ON  c13.RefNo  = c17.RefNo
  AND c13.CaseNo = c17.CaseNo
  AND c13.InvNo  = c17.InvNo
  AND c13.Clone  = c17.Clone
JOIN `mitelman-db.prod.CytoConverted` AS c11
  ON  c13.RefNo  = c11.RefNo
  AND c13.CaseNo = c11.CaseNo
  AND c13.InvNo  = c11.InvNo
  AND c13.Clone  = c11.Clone
JOIN `mitelman-db.prod.KaryClone`      AS kc
  ON  c13.RefNo  = kc.RefNo
  AND c13.CaseNo = kc.CaseNo
  AND c13.InvNo  = kc.InvNo
  AND c13.Clone  = kc.CloneNo
WHERE
      -- chr-13 loss: 48,303,751-48,481,890
      c13.ChrOrd = 13
  AND c13.Type   = 'Loss'
  AND c13.Start <= 48481890
  AND c13.End   >= 48303751

      -- chr-17 loss: 7,668,421-7,687,490
  AND c17.ChrOrd = 17
  AND c17.Type   = 'Loss'
  AND c17.Start <= 7687490
  AND c17.End   >= 7668421

      -- chr-11 gain: 108,223,067-108,369,102
  AND c11.ChrOrd = 11
  AND c11.Type   = 'Gain'
  AND c11.Start <= 108369102
  AND c11.End   >= 108223067
ORDER BY
  RefNo, CaseNo, InvNo, CloneNo;