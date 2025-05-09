-- Distinct clones that show
--  1) chr13 loss   48,303,751-48,481,890
--  2) chr17 loss    7,668,421- 7,687,490
--  3) chr11 gain 108,223,067-108,369,102
-- together with cytogenomic coordinates for the three regions
-- and the short karyotype description
WITH matched_clones AS (
  SELECT DISTINCT a.RefNo,
                  a.CaseNo,
                  a.InvNo,
                  a.Clone
  FROM `mitelman-db.prod.CytoConverted` AS a
  JOIN `mitelman-db.prod.CytoConverted` AS b
    ON  a.RefNo  = b.RefNo
   AND a.CaseNo = b.CaseNo
   AND a.InvNo  = b.InvNo
   AND a.Clone  = b.Clone
  JOIN `mitelman-db.prod.CytoConverted` AS c
    ON  a.RefNo  = c.RefNo
   AND a.CaseNo = c.CaseNo
   AND a.InvNo  = c.InvNo
   AND a.Clone  = c.Clone
  WHERE
        -- chr13 loss
        a.ChrOrd = 13
    AND a.Type   = 'Loss'
    AND a.Start <= 48481890
    AND a.End   >= 48303751

        -- chr17 loss
    AND b.ChrOrd = 17
    AND b.Type   = 'Loss'
    AND b.Start <=  7687490
    AND b.End   >=  7668421

        -- chr11 gain
    AND c.ChrOrd = 11
    AND c.Type   = 'Gain'
    AND c.Start <= 108369102
    AND c.End   >= 108223067
)

SELECT
    m.RefNo,
    m.CaseNo,
    m.InvNo,
    m.Clone,

    MAX(IF(cc.ChrOrd = 13, cc.ChrOrd, NULL))  AS Chr13_ChrOrd,
    MAX(IF(cc.ChrOrd = 13, cc.Start  , NULL)) AS Chr13_Start,
    MAX(IF(cc.ChrOrd = 13, cc.End    , NULL)) AS Chr13_End,

    MAX(IF(cc.ChrOrd = 17, cc.ChrOrd, NULL))  AS Chr17_ChrOrd,
    MAX(IF(cc.ChrOrd = 17, cc.Start  , NULL)) AS Chr17_Start,
    MAX(IF(cc.ChrOrd = 17, cc.End    , NULL)) AS Chr17_End,

    MAX(IF(cc.ChrOrd = 11, cc.ChrOrd, NULL))  AS Chr11_ChrOrd,
    MAX(IF(cc.ChrOrd = 11, cc.Start  , NULL)) AS Chr11_Start,
    MAX(IF(cc.ChrOrd = 11, cc.End    , NULL)) AS Chr11_End,

    k.CloneShort
FROM matched_clones AS m
JOIN `mitelman-db.prod.CytoConverted` AS cc
  ON  m.RefNo  = cc.RefNo
 AND m.CaseNo = cc.CaseNo
 AND m.InvNo  = cc.InvNo
 AND m.Clone  = cc.Clone
 -- keep only the three relevant cytogenomic segments
 AND (
        (cc.ChrOrd = 13 AND cc.Type = 'Loss' AND cc.Start <= 48481890 AND cc.End >= 48303751)
     OR (cc.ChrOrd = 17 AND cc.Type = 'Loss' AND cc.Start <=  7687490 AND cc.End >=  7668421)
     OR (cc.ChrOrd = 11 AND cc.Type = 'Gain' AND cc.Start <=108369102 AND cc.End >=108223067)
 )
LEFT JOIN `mitelman-db.prod.KaryClone` AS k
  ON  m.RefNo  = k.RefNo
 AND m.CaseNo = k.CaseNo
 AND m.InvNo  = k.InvNo
 AND m.Clone  = k.CloneNo
GROUP BY
    m.RefNo,
    m.CaseNo,
    m.InvNo,
    m.Clone,
    k.CloneShort
ORDER BY
    m.RefNo,
    m.CaseNo,
    m.InvNo,
    m.Clone;