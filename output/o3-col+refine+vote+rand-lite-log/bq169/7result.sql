SELECT DISTINCT
  c13.RefNo                 AS RefNo,
  c13.CaseNo                AS CaseNo,
  c13.InvNo                 AS InvNo,
  c13.Clone                 AS CloneNo,

  -- chr-13 loss segment
  c13.ChrOrd                AS Chr13_Ord,
  c13.Start                 AS Chr13_Start,
  c13.End                   AS Chr13_End,

  -- chr-17 loss segment
  c17.ChrOrd                AS Chr17_Ord,
  c17.Start                 AS Chr17_Start,
  c17.End                   AS Chr17_End,

  -- chr-11 gain segment
  c11.ChrOrd                AS Chr11_Ord,
  c11.Start                 AS Chr11_Start,
  c11.End                   AS Chr11_End,

  kc.CloneShort             AS KaryotypeShort
FROM `mitelman-db.prod.CytoConverted` AS c13
JOIN `mitelman-db.prod.CytoConverted` AS c17   -- same clone, chromosome-17 loss
  ON c17.RefNo  = c13.RefNo
 AND c17.CaseNo = c13.CaseNo
 AND c17.InvNo  = c13.InvNo
 AND c17.Clone  = c13.Clone
JOIN `mitelman-db.prod.CytoConverted` AS c11   -- same clone, chromosome-11 gain
  ON c11.RefNo  = c13.RefNo
 AND c11.CaseNo = c13.CaseNo
 AND c11.InvNo  = c13.InvNo
 AND c11.Clone  = c13.Clone
JOIN `mitelman-db.prod.KaryClone`      AS kc   -- karyotype description
  ON kc.RefNo   = c13.RefNo
 AND kc.CaseNo  = c13.CaseNo
 AND kc.InvNo   = c13.InvNo
 AND kc.CloneNo = c13.Clone
WHERE
  -- chr-13 loss: 48 303 751 – 48 481 890
  c13.ChrOrd = 13
  AND c13.Type  = 'Loss'
  AND c13.End   > 48303751
  AND c13.Start < 48481890

  -- chr-17 loss: 7 668 421 – 7 687 490
  AND c17.ChrOrd = 17
  AND c17.Type   = 'Loss'
  AND c17.End    >  7668421
  AND c17.Start  <  7687490

  -- chr-11 gain: 108 223 067 – 108 369 102
  AND c11.ChrOrd = 11
  AND c11.Type   = 'Gain'
  AND c11.End    > 108223067
  AND c11.Start  < 108369102
ORDER BY RefNo, CaseNo, InvNo, CloneNo;