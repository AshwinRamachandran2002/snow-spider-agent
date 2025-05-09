-- Retrieve clones that simultaneously show:
--   1) chr13 loss (48,303,751‒48,481,890)
--   2) chr17 loss (7,668,421‒7,687,490)
--   3) chr11 gain (108,223,067‒108,369,102)
-- and list their karyotype description
SELECT DISTINCT
       c13.RefNo,
       c13.CaseNo,
       c13.InvNo,
       c13.Clone                    AS CloneNo,

       -- chr13-loss segment
       c13.ChrOrd                   AS chr13_ChrOrd,
       c13.`Start`                  AS chr13_Start,
       c13.`End`                    AS chr13_End,

       -- chr17-loss segment
       c17.ChrOrd                   AS chr17_ChrOrd,
       c17.`Start`                  AS chr17_Start,
       c17.`End`                    AS chr17_End,

       -- chr11-gain segment
       c11.ChrOrd                   AS chr11_ChrOrd,
       c11.`Start`                  AS chr11_Start,
       c11.`End`                    AS chr11_End,

       kc.CloneShort
FROM   `mitelman-db.prod.CytoConverted` AS c13
JOIN   `mitelman-db.prod.CytoConverted` AS c17
         USING (RefNo, CaseNo, InvNo, Clone)
JOIN   `mitelman-db.prod.CytoConverted` AS c11
         USING (RefNo, CaseNo, InvNo, Clone)
JOIN   `mitelman-db.prod.KaryClone`     AS kc
       ON  kc.RefNo   = c13.RefNo
       AND kc.CaseNo  = c13.CaseNo
       AND kc.InvNo   = c13.InvNo
       AND kc.CloneNo = c13.Clone
WHERE  c13.ChrOrd = 13 AND c13.Type = 'Loss'
  AND  c13.`Start` <=  48481890  AND c13.`End` >= 48303751     -- chr13 interval
  AND  c17.ChrOrd = 17 AND c17.Type = 'Loss'
  AND  c17.`Start` <=   7687490  AND c17.`End` >=  7668421     -- chr17 interval
  AND  c11.ChrOrd = 11 AND c11.Type = 'Gain'
  AND  c11.`Start` <= 108369102  AND c11.`End` >=108223067     -- chr11 interval
ORDER BY RefNo, CaseNo, InvNo, CloneNo;