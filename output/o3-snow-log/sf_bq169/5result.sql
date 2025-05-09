/*  Clones that harbor:  
    1) chr 13 loss spanning 48,303,751-48,481,890  
    2) chr 17 loss spanning  7,668,421- 7,687,490  
    3) chr 11 gain spanning 108,223,067-108,369,102  
    with karyotype description                                                      */
SELECT DISTINCT
       t."RefNo",
       t."CaseNo",
       t."InvNo",
       t."CloneNo",
       t."Chr13_ChrOrd",
       t."Chr13_Start",
       t."Chr13_End",
       t."Chr17_ChrOrd",
       t."Chr17_Start",
       t."Chr17_End",
       t."Chr11_ChrOrd",
       t."Chr11_Start",
       t."Chr11_End",
       kc."CloneShort"
FROM (
        /* ---------- clones that satisfy all three segment criteria ---------- */
        SELECT
               c13."RefNo",
               c13."CaseNo",
               c13."InvNo",
               c13."Clone"      AS "CloneNo",
               c13."ChrOrd"     AS "Chr13_ChrOrd",
               c13."Start"      AS "Chr13_Start",
               c13."End"        AS "Chr13_End",
               c17."ChrOrd"     AS "Chr17_ChrOrd",
               c17."Start"      AS "Chr17_Start",
               c17."End"        AS "Chr17_End",
               c11."ChrOrd"     AS "Chr11_ChrOrd",
               c11."Start"      AS "Chr11_Start",
               c11."End"        AS "Chr11_End"
        FROM MITELMAN.PROD.CYTOCONVERTED c13
        JOIN MITELMAN.PROD.CYTOCONVERTED c17
          ON c13."RefNo"  = c17."RefNo"
         AND c13."CaseNo" = c17."CaseNo"
         AND c13."InvNo"  = c17."InvNo"
         AND c13."Clone"  = c17."Clone"
        JOIN MITELMAN.PROD.CYTOCONVERTED c11
          ON c13."RefNo"  = c11."RefNo"
         AND c13."CaseNo" = c11."CaseNo"
         AND c13."InvNo"  = c11."InvNo"
         AND c13."Clone"  = c11."Clone"
        WHERE c13."ChrOrd" = 13
          AND c13."Type"   = 'Loss'
          AND c13."Start" <= 48303751
          AND c13."End"   >= 48481890
          AND c17."ChrOrd" = 17
          AND c17."Type"   = 'Loss'
          AND c17."Start" <=  7668421
          AND c17."End"   >=  7687490
          AND c11."ChrOrd" = 11
          AND c11."Type"   = 'Gain'
          AND c11."Start" <= 108223067
          AND c11."End"   >= 108369102
     ) t
LEFT JOIN MITELMAN.PROD.KARYCLONE kc
       ON kc."RefNo"    = t."RefNo"
      AND kc."CaseNo"   = t."CaseNo"
      AND kc."InvNo"    = t."InvNo"
      AND kc."CloneNo"  = t."CloneNo"
ORDER BY t."RefNo", t."CaseNo", t."InvNo", t."CloneNo";