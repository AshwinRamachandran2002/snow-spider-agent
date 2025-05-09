SELECT DISTINCT
       a.RefNo                      AS RefNo,
       a.CaseNo                     AS CaseNo,
       a.InvNo                      AS InvNo,
       a.Clone                      AS CloneNo,
       kc.CloneShort                AS KaryotypeShort,

       -- chr13 loss interval
       a.ChrOrd                     AS ChrOrd13,
       a.Start                      AS Start13,
       a.End                        AS End13,

       -- chr17 loss interval
       b.ChrOrd                     AS ChrOrd17,
       b.Start                      AS Start17,
       b.End                        AS End17,

       -- chr11 gain interval
       c.ChrOrd                     AS ChrOrd11,
       c.Start                      AS Start11,
       c.End                        AS End11
FROM   `mitelman-db.prod.CytoConverted` AS a          -- chr13 loss
JOIN   `mitelman-db.prod.CytoConverted` AS b          -- chr17 loss
       ON  a.RefNo  = b.RefNo
       AND a.CaseNo = b.CaseNo
       AND a.InvNo  = b.InvNo
       AND a.Clone  = b.Clone
JOIN   `mitelman-db.prod.CytoConverted` AS c          -- chr11 gain
       ON  a.RefNo  = c.RefNo
       AND a.CaseNo = c.CaseNo
       AND a.InvNo  = c.InvNo
       AND a.Clone  = c.Clone
JOIN   `mitelman-db.prod.KaryClone` AS kc
       ON  a.RefNo  = kc.RefNo
       AND a.CaseNo = kc.CaseNo
       AND a.InvNo  = kc.InvNo
       AND a.Clone  = kc.CloneNo
WHERE  a.ChrOrd = 13
  AND  a.Type   = 'Loss'
  AND  a.Start <= 48481890
  AND  a.End   >= 48303751         -- overlaps 48,303,751–48,481,890

  AND  b.ChrOrd = 17
  AND  b.Type   = 'Loss'
  AND  b.Start <=  7687490
  AND  b.End   >=  7668421         -- overlaps 7,668,421–7,687,490

  AND  c.ChrOrd = 11
  AND  c.Type   = 'Gain'
  AND  c.Start <= 108369102
  AND  c.End   >= 108223067        -- overlaps 108,223,067–108,369,102
ORDER BY
       RefNo,
       CaseNo,
       InvNo,
       CloneNo;