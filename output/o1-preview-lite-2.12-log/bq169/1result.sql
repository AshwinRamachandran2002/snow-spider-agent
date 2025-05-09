WITH clones_with_conditions AS (
  SELECT cc.RefNo, cc.CaseNo, cc.InvNo, cc.Clone
  FROM `mitelman-db.prod.CytoConverted` AS cc
  GROUP BY cc.RefNo, cc.CaseNo, cc.InvNo, cc.Clone
  HAVING
    SUM(CASE WHEN cc.Chr = 'chr13' AND LOWER(cc.Type) = 'loss' AND cc.Start <= 48481890 AND cc.`End` >= 48303751 THEN 1 ELSE 0 END) > 0
    AND
    SUM(CASE WHEN cc.Chr = 'chr17' AND LOWER(cc.Type) = 'loss' AND cc.Start <= 7687490 AND cc.`End` >= 7668421 THEN 1 ELSE 0 END) > 0
    AND
    SUM(CASE WHEN cc.Chr = 'chr11' AND LOWER(cc.Type) = 'gain' AND cc.Start <= 108369102 AND cc.`End` >= 108223067 THEN 1 ELSE 0 END) > 0
)
SELECT
  cwc.RefNo,
  cwc.CaseNo,
  cwc.InvNo,
  cwc.Clone AS CloneNo,
  MAX(IF(cc.Chr = 'chr13' AND LOWER(cc.Type) = 'loss', cc.Start, NULL)) AS Chr13_Start,
  MIN(IF(cc.Chr = 'chr13' AND LOWER(cc.Type) = 'loss', cc.`End`, NULL)) AS Chr13_End,
  MAX(IF(cc.Chr = 'chr17' AND LOWER(cc.Type) = 'loss', cc.Start, NULL)) AS Chr17_Start,
  MIN(IF(cc.Chr = 'chr17' AND LOWER(cc.Type) = 'loss', cc.`End`, NULL)) AS Chr17_End,
  MIN(IF(cc.Chr = 'chr11' AND LOWER(cc.Type) = 'gain', cc.Start, NULL)) AS Chr11_Start,
  MAX(IF(cc.Chr = 'chr11' AND LOWER(cc.Type) = 'gain', cc.`End`, NULL)) AS Chr11_End,
  COALESCE(NULLIF(TRIM(kc.CloneLong), ''), NULLIF(TRIM(kc.CloneShort), '')) AS Karyotype
FROM
  clones_with_conditions cwc
JOIN `mitelman-db.prod.CytoConverted` cc
  ON cwc.RefNo = cc.RefNo AND cwc.CaseNo = cc.CaseNo AND cwc.InvNo = cc.InvNo AND cwc.Clone = cc.Clone
JOIN `mitelman-db.prod.KaryClone` kc
  ON cwc.RefNo = kc.RefNo AND cwc.CaseNo = kc.CaseNo AND cwc.InvNo = kc.InvNo AND cwc.Clone = kc.CloneNo
GROUP BY
  cwc.RefNo, cwc.CaseNo, cwc.InvNo, cwc.Clone, Karyotype
HAVING
  MIN(IF(cc.Chr = 'chr13' AND LOWER(cc.Type) = 'loss', 1, NULL)) = 1 AND
  MIN(IF(cc.Chr = 'chr17' AND LOWER(cc.Type) = 'loss', 1, NULL)) = 1 AND
  MIN(IF(cc.Chr = 'chr11' AND LOWER(cc.Type) = 'gain', 1, NULL)) = 1;