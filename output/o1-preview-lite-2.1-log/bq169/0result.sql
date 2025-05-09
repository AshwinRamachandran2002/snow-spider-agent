SELECT DISTINCT
  kb13.RefNo,
  kb13.CaseNo,
  kb13.InvNo,
  kb13.CloneNo AS CloneNo,
  kb13.Breakpoint AS Chr13_Breakpoint,
  kb17.Breakpoint AS Chr17_Breakpoint,
  kb11.Breakpoint AS Chr11_Breakpoint,
  COALESCE(kc.CloneLong, kc.CloneShort) AS Karyotype
FROM
  `mitelman-db.prod.KaryBreak` kb13
JOIN
  `mitelman-db.prod.KaryBreak` kb17
  ON kb13.RefNo = kb17.RefNo
  AND kb13.CaseNo = kb17.CaseNo
  AND kb13.InvNo = kb17.InvNo
  AND kb13.CloneNo = kb17.CloneNo
JOIN
  `mitelman-db.prod.KaryBreak` kb11
  ON kb13.RefNo = kb11.RefNo
  AND kb13.CaseNo = kb11.CaseNo
  AND kb13.InvNo = kb11.InvNo
  AND kb13.CloneNo = kb11.CloneNo
LEFT JOIN
  `mitelman-db.prod.KaryClone` kc
  ON kb13.RefNo = kc.RefNo
  AND kb13.CaseNo = kc.CaseNo
  AND kb13.InvNo = kc.InvNo
  AND kb13.CloneNo = kc.CloneNo
WHERE
  kb13.Breakpoint LIKE '13q14%'
  AND kb17.Breakpoint LIKE '17p1%'
  AND kb11.Breakpoint LIKE '11q23%';