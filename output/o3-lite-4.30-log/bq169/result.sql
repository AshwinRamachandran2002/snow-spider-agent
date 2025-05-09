/* -----------------------------------------------------------------
   Find every clone that simultaneously shows
     1) a LOSS on chromosome 13 overlapping 48 303 751‑48 481 890
     2) a LOSS on chromosome 17 overlapping  7 668 421‑ 7 687 490
     3) a GAIN on chromosome 11 overlapping 108 223 067‑108 369 102
   and list the requested details together with CloneShort.
   ----------------------------------------------------------------- */

WITH
-- Chr 13 LOSS overlapping the required window
region13 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone                           AS CloneNo,
    13                              AS Chr13_Ord,
    MIN(GREATEST(Start , 48303751)) AS Chr13_Start,
    MAX(LEAST   (`End`, 48481890)) AS Chr13_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 13
    AND Type   = 'Loss'
    AND Start <= 48481890
    AND `End` >= 48303751
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- Chr 17 LOSS overlapping the required window
region17 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone                           AS CloneNo,
    17                              AS Chr17_Ord,
    MIN(GREATEST(Start ,  7668421)) AS Chr17_Start,
    MAX(LEAST   (`End`,  7687490)) AS Chr17_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 17
    AND Type   = 'Loss'
    AND Start <=  7687490
    AND `End` >=  7668421
  GROUP BY RefNo, CaseNo, InvNo, Clone
),

-- Chr 11 GAIN overlapping the required window
region11 AS (
  SELECT
    RefNo,
    CaseNo,
    InvNo,
    Clone                           AS CloneNo,
    11                              AS Chr11_Ord,
    MIN(GREATEST(Start , 108223067)) AS Chr11_Start,
    MAX(LEAST   (`End`, 108369102)) AS Chr11_End
  FROM `mitelman-db.prod.CytoConverted`
  WHERE ChrOrd = 11
    AND Type   = 'Gain'
    AND Start <= 108369102
    AND `End` >= 108223067
  GROUP BY RefNo, CaseNo, InvNo, Clone
)

SELECT
  r13.RefNo          AS case_reference,
  r13.CaseNo         AS case_number,
  r13.InvNo          AS investigation_number,
  r13.CloneNo        AS clone_name,

  r13.Chr13_Ord      AS chr13_ord,
  r13.Chr13_Start    AS chr13_start,
  r13.Chr13_End      AS chr13_end,

  r17.Chr17_Ord      AS chr17_ord,
  r17.Chr17_Start    AS chr17_start,
  r17.Chr17_End      AS chr17_end,

  r11.Chr11_Ord      AS chr11_ord,
  r11.Chr11_Start    AS chr11_start,
  r11.Chr11_End      AS chr11_end,

  kc.CloneShort      AS karyotype_short
FROM region13 r13
JOIN region17 r17
  ON r13.RefNo   = r17.RefNo
 AND r13.CaseNo  = r17.CaseNo
 AND r13.InvNo   = r17.InvNo
 AND r13.CloneNo = r17.CloneNo
JOIN region11 r11
  ON r13.RefNo   = r11.RefNo
 AND r13.CaseNo  = r11.CaseNo
 AND r13.InvNo   = r11.InvNo
 AND r13.CloneNo = r11.CloneNo
LEFT JOIN `mitelman-db.prod.KaryClone` kc
  ON kc.RefNo    = r13.RefNo
 AND kc.CaseNo   = r13.CaseNo
 AND kc.InvNo    = r13.InvNo
 AND kc.CloneNo  = r13.CloneNo
ORDER BY
  case_reference,
  case_number,
  investigation_number,
  clone_name;