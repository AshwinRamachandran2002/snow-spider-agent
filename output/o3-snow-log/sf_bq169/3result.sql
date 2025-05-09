/*  Clones that show: 
    – Loss on Chr 13 covering 48 303 751–48 481 890
    – Loss on Chr 17 covering 7 668 421–7 687 490
    – Gain on Chr 11 covering 108 223 067–108 369 102
    plus their karyotype short description
*/
SELECT DISTINCT
       chr13."RefNo",
       chr13."CaseNo",
       chr13."InvNo",
       chr13."Clone"              AS "CloneNo",

       chr13."ChrOrd"             AS "ChrOrd_13",
       chr13."Start"              AS "Start_13",
       chr13."End"                AS "End_13",

       chr17."ChrOrd"             AS "ChrOrd_17",
       chr17."Start"              AS "Start_17",
       chr17."End"                AS "End_17",

       chr11."ChrOrd"             AS "ChrOrd_11",
       chr11."Start"              AS "Start_11",
       chr11."End"                AS "End_11",

       k."CloneShort"
FROM   MITELMAN.PROD.CYTOCONVERTED   chr13
JOIN   MITELMAN.PROD.CYTOCONVERTED   chr17
       ON  chr13."RefNo"  = chr17."RefNo"
       AND chr13."CaseNo" = chr17."CaseNo"
       AND chr13."InvNo"  = chr17."InvNo"
       AND chr13."Clone"  = chr17."Clone"
JOIN   MITELMAN.PROD.CYTOCONVERTED   chr11
       ON  chr13."RefNo"  = chr11."RefNo"
       AND chr13."CaseNo" = chr11."CaseNo"
       AND chr13."InvNo"  = chr11."InvNo"
       AND chr13."Clone"  = chr11."Clone"
LEFT JOIN MITELMAN.PROD.KARYCLONE    k
       ON  k."RefNo"    = chr13."RefNo"
       AND k."CaseNo"   = chr13."CaseNo"
       AND k."InvNo"    = chr13."InvNo"
       AND k."CloneNo"  = chr13."Clone"
WHERE  chr13."ChrOrd" = 13
  AND  chr13."Type"   = 'Loss'
  AND  chr13."Start" <= 48303751      -- region lower bound
  AND  chr13."End"   >= 48481890      -- region upper bound

  AND  chr17."ChrOrd" = 17
  AND  chr17."Type"   = 'Loss'
  AND  chr17."Start" <= 7668421
  AND  chr17."End"   >= 7687490

  AND  chr11."ChrOrd" = 11
  AND  chr11."Type"   = 'Gain'
  AND  chr11."Start" <= 108223067
  AND  chr11."End"   >= 108369102
ORDER BY
       chr13."RefNo",
       chr13."CaseNo",
       chr13."InvNo",
       chr13."Clone";