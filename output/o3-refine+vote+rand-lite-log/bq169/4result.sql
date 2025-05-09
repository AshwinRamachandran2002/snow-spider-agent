/*  Retrieve every clone that, at the same time,
    – has a LOSS on chr13 covering 48 303 751‑48 481 890
    – has a LOSS on chr17 covering 7 668 421‑7 687 490
    – has a GAIN on chr11 covering 108 223 067‑108 369 102

    For each qualifying clone return the reference, case, investigation,
    clone number, the karyotype (CloneShort), and the chromosomal
    segment details that satisfy each of the three conditions.
*/

SELECT DISTINCT
    c13.RefNo,
    c13.CaseNo,
    c13.InvNo,
    c13.Clone            AS CloneNo,
    kc.CloneShort        AS Karyotype,
    -- chr13 loss segment
    c13.ChrOrd           AS Chr13_ChrOrd,
    c13.Start            AS Chr13_Start,
    c13.End              AS Chr13_End,
    -- chr17 loss segment
    c17.ChrOrd           AS Chr17_ChrOrd,
    c17.Start            AS Chr17_Start,
    c17.End              AS Chr17_End,
    -- chr11 gain segment
    c11.ChrOrd           AS Chr11_ChrOrd,
    c11.Start            AS Chr11_Start,
    c11.End              AS Chr11_End
FROM `mitelman-db.prod.CytoConverted` c13
JOIN `mitelman-db.prod.CytoConverted` c17
  ON  c13.RefNo  = c17.RefNo
  AND c13.CaseNo = c17.CaseNo
  AND c13.InvNo  = c17.InvNo
  AND c13.Clone  = c17.Clone
JOIN `mitelman-db.prod.CytoConverted` c11
  ON  c13.RefNo  = c11.RefNo
  AND c13.CaseNo = c11.CaseNo
  AND c13.InvNo  = c11.InvNo
  AND c13.Clone  = c11.Clone
JOIN `mitelman-db.prod.KaryClone` kc
  ON  c13.RefNo  = kc.RefNo
  AND c13.CaseNo = kc.CaseNo
  AND c13.InvNo  = kc.InvNo
  AND c13.Clone  = kc.CloneNo
WHERE
      -- chr13 LOSS covering the target interval
      c13.Type = 'Loss'
  AND c13.Chr  = 'chr13'
  AND c13.Start <= 48303751
  AND c13.End   >= 48481890

      -- chr17 LOSS covering the target interval
  AND c17.Type = 'Loss'
  AND c17.Chr  = 'chr17'
  AND c17.Start <= 7668421
  AND c17.End   >= 7687490

      -- chr11 GAIN covering the target interval
  AND c11.Type = 'Gain'
  AND c11.Chr  = 'chr11'
  AND c11.Start <= 108223067
  AND c11.End   >= 108369102;