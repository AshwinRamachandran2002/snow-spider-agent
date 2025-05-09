WITH clones_with_all_conditions AS (
  SELECT RefNo, CaseNo, InvNo, Clone
  FROM `mitelman-db.prod.CytoConverted`
  WHERE 
    ((Chr = '13' OR Chr = 'chr13') AND LOWER(Type) = 'loss' AND Start <= 48481890 AND `End` >= 48303751)
    OR ((Chr = '17' OR Chr = 'chr17') AND LOWER(Type) = 'loss' AND Start <= 7687490 AND `End` >= 7668421)
    OR ((Chr = '11' OR Chr = 'chr11') AND LOWER(Type) = 'gain' AND Start <= 108369102 AND `End` >= 108223067)
  GROUP BY RefNo, CaseNo, InvNo, Clone
  HAVING COUNT(DISTINCT CASE
    WHEN (Chr = '13' OR Chr = 'chr13') AND LOWER(Type) = 'loss' THEN '13_loss'
    WHEN (Chr = '17' OR Chr = 'chr17') AND LOWER(Type) = 'loss' THEN '17_loss'
    WHEN (Chr = '11' OR Chr = 'chr11') AND LOWER(Type) = 'gain' THEN '11_gain'
    END) = 3
)

SELECT 
  c.RefNo, 
  c.CaseNo, 
  c.InvNo, 
  c.Clone AS CloneNo,
  MAX(CASE WHEN (c.Chr = '13' OR c.Chr = 'chr13') AND LOWER(c.Type) = 'loss' THEN c.Start END) AS Chr13_Start,
  MAX(CASE WHEN (c.Chr = '13' OR c.Chr = 'chr13') AND LOWER(c.Type) = 'loss' THEN c.`End` END) AS Chr13_End,
  MAX(CASE WHEN (c.Chr = '17' OR c.Chr = 'chr17') AND LOWER(c.Type) = 'loss' THEN c.Start END) AS Chr17_Start,
  MAX(CASE WHEN (c.Chr = '17' OR c.Chr = 'chr17') AND LOWER(c.Type) = 'loss' THEN c.`End` END) AS Chr17_End,
  MAX(CASE WHEN (c.Chr = '11' OR c.Chr = 'chr11') AND LOWER(c.Type) = 'gain' THEN c.Start END) AS Chr11_Start,
  MAX(CASE WHEN (c.Chr = '11' OR c.Chr = 'chr11') AND LOWER(c.Type) = 'gain' THEN c.`End` END) AS Chr11_End,
  COALESCE(kc.CloneLong, kc.CloneShort) AS Karyotype
FROM `mitelman-db.prod.CytoConverted` AS c
JOIN clones_with_all_conditions AS cwac
  ON c.RefNo = cwac.RefNo AND c.CaseNo = cwac.CaseNo AND c.InvNo = cwac.InvNo AND c.Clone = cwac.Clone
LEFT JOIN `mitelman-db.prod.KaryClone` AS kc
  ON c.RefNo = kc.RefNo AND c.CaseNo = kc.CaseNo AND c.InvNo = kc.InvNo AND c.Clone = kc.CloneNo
GROUP BY c.RefNo, c.CaseNo, c.InvNo, c.Clone, Karyotype
ORDER BY c.RefNo, c.CaseNo, c.InvNo, c.Clone;