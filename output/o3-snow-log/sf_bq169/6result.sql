/*  Clones that show:
      1)  chr13 LOSS overlapping 48,303,751-48,481,890
      2)  chr17 LOSS overlapping  7,668,421- 7,687,490
      3)  chr11 GAIN overlapping 108,223,067-108,369,102
    together with the cytogenetic details for each region
    and the clone’s short karyotype description               */
SELECT DISTINCT
       base."RefNo",
       base."CaseNo",
       base."InvNo",
       base."Clone"                       AS "CloneNo",
       kc."CloneShort",

       chr13."ChrOrd"  AS "Chr13_Ord",
       chr13."Start"   AS "Chr13_Start",
       chr13."End"     AS "Chr13_End",

       chr17."ChrOrd"  AS "Chr17_Ord",
       chr17."Start"   AS "Chr17_Start",
       chr17."End"     AS "Chr17_End",

       chr11."ChrOrd"  AS "Chr11_Ord",
       chr11."Start"   AS "Chr11_Start",
       chr11."End"     AS "Chr11_End"
FROM (
        /*── identify every clone that harbours ALL three alterations ──*/
        SELECT "RefNo",
               "CaseNo",
               "InvNo",
               "Clone"
        FROM   MITELMAN.PROD.CYTOCONVERTED
        WHERE  (   ("Chr" = 'chr13' AND "Type" = 'Loss'
                    AND "Start" <= 48303751 AND "End" >= 48481890)
               OR  ("Chr" = 'chr17' AND "Type" = 'Loss'
                    AND "Start" <=  7668421 AND "End" >=  7687490)
               OR  ("Chr" = 'chr11' AND "Type" = 'Gain'
                    AND "Start" <=108223067 AND "End" >=108369102)
              )
        GROUP  BY "RefNo", "CaseNo", "InvNo", "Clone"
        HAVING COUNT(DISTINCT
                     CASE
                         WHEN "Chr" = 'chr13' THEN 'chr13'
                         WHEN "Chr" = 'chr17' THEN 'chr17'
                         WHEN "Chr" = 'chr11' THEN 'chr11'
                     END) = 3
     ) base
/*── bring in the exact rows for each alteration ───────────────────────*/
JOIN MITELMAN.PROD.CYTOCONVERTED chr13
  ON chr13."RefNo"  = base."RefNo"
 AND chr13."CaseNo" = base."CaseNo"
 AND chr13."InvNo"  = base."InvNo"
 AND chr13."Clone"  = base."Clone"
 AND chr13."Chr"    = 'chr13'
 AND chr13."Type"   = 'Loss'
 AND chr13."Start" <= 48303751
 AND chr13."End"   >= 48481890

JOIN MITELMAN.PROD.CYTOCONVERTED chr17
  ON chr17."RefNo"  = base."RefNo"
 AND chr17."CaseNo" = base."CaseNo"
 AND chr17."InvNo"  = base."InvNo"
 AND chr17."Clone"  = base."Clone"
 AND chr17."Chr"    = 'chr17'
 AND chr17."Type"   = 'Loss'
 AND chr17."Start" <=  7668421
 AND chr17."End"   >=  7687490

JOIN MITELMAN.PROD.CYTOCONVERTED chr11
  ON chr11."RefNo"  = base."RefNo"
 AND chr11."CaseNo" = base."CaseNo"
 AND chr11."InvNo"  = base."InvNo"
 AND chr11."Clone"  = base."Clone"
 AND chr11."Chr"    = 'chr11'
 AND chr11."Type"   = 'Gain'
 AND chr11."Start" <=108223067
 AND chr11."End"   >=108369102

/*── karyotype short description ───────────────────────────────────────*/
JOIN MITELMAN.PROD.KARYCLONE kc
  ON kc."RefNo"   = base."RefNo"
 AND kc."CaseNo"  = base."CaseNo"
 AND kc."InvNo"   = base."InvNo"
 AND kc."CloneNo" = base."Clone"

ORDER BY base."RefNo",
         base."CaseNo",
         base."InvNo",
         base."Clone";