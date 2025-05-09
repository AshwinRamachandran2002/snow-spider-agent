/* clones that contain ALL three required alterations */
WITH
/* 1) chr-13 loss: 48,303,751 – 48,481,890 (hg38) */
chr13_loss AS (
    SELECT
        "RefNo",
        "CaseNo",
        "InvNo",
        "Clone"        AS "CloneNo",
        "ChrOrd"       AS "Chr13_Ord",
        "Start"        AS "Chr13_Start",
        "End"          AS "Chr13_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "ChrOrd" = 13
      AND "Type"   = 'Loss'
      AND "Start" <= 48303751
      AND "End"   >= 48481890
),
/* 2) chr-17 loss: 7,668,421 – 7,687,490 (hg38) */
chr17_loss AS (
    SELECT
        "RefNo",
        "CaseNo",
        "InvNo",
        "Clone"        AS "CloneNo",
        "ChrOrd"       AS "Chr17_Ord",
        "Start"        AS "Chr17_Start",
        "End"          AS "Chr17_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "ChrOrd" = 17
      AND "Type"   = 'Loss'
      AND "Start" <=  7668421
      AND "End"   >=  7687490
),
/* 3) chr-11 gain: 108,223,067 – 108,369,102 (hg38) */
chr11_gain AS (
    SELECT
        "RefNo",
        "CaseNo",
        "InvNo",
        "Clone"        AS "CloneNo",
        "ChrOrd"       AS "Chr11_Ord",
        "Start"        AS "Chr11_Start",
        "End"          AS "Chr11_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "ChrOrd" = 11
      AND "Type"   = 'Gain'
      AND "Start" <= 108223067
      AND "End"   >= 108369102
),
/* clones that satisfy all three conditions */
intersect_clones AS (
    SELECT DISTINCT
        c13."RefNo",
        c13."CaseNo",
        c13."InvNo",
        c13."CloneNo"
    FROM chr13_loss c13
    INNER JOIN chr17_loss c17
           ON  c17."RefNo"   = c13."RefNo"
           AND c17."CaseNo"  = c13."CaseNo"
           AND c17."InvNo"   = c13."InvNo"
           AND c17."CloneNo" = c13."CloneNo"
    INNER JOIN chr11_gain c11
           ON  c11."RefNo"   = c13."RefNo"
           AND c11."CaseNo"  = c13."CaseNo"
           AND c11."InvNo"   = c13."InvNo"
           AND c11."CloneNo" = c13."CloneNo"
)
/* final output with coordinates for each alteration + karyotype */
SELECT DISTINCT
       ic."RefNo",
       ic."CaseNo",
       ic."InvNo",
       ic."CloneNo"                         AS "Clone",
       k."CloneShort",
       c13."Chr13_Ord",
       c13."Chr13_Start",
       c13."Chr13_End",
       c17."Chr17_Ord",
       c17."Chr17_Start",
       c17."Chr17_End",
       c11."Chr11_Ord",
       c11."Chr11_Start",
       c11."Chr11_End"
FROM intersect_clones      ic
JOIN chr13_loss            c13
  ON ic."RefNo"   = c13."RefNo"
 AND ic."CaseNo"  = c13."CaseNo"
 AND ic."InvNo"   = c13."InvNo"
 AND ic."CloneNo" = c13."CloneNo"
JOIN chr17_loss            c17
  ON ic."RefNo"   = c17."RefNo"
 AND ic."CaseNo"  = c17."CaseNo"
 AND ic."InvNo"   = c17."InvNo"
 AND ic."CloneNo" = c17."CloneNo"
JOIN chr11_gain            c11
  ON ic."RefNo"   = c11."RefNo"
 AND ic."CaseNo"  = c11."CaseNo"
 AND ic."InvNo"   = c11."InvNo"
 AND ic."CloneNo" = c11."CloneNo"
LEFT JOIN MITELMAN.PROD.KARYCLONE k
       ON k."RefNo"   = ic."RefNo"
      AND k."CaseNo"  = ic."CaseNo"
      AND k."InvNo"   = ic."InvNo"
      AND k."CloneNo" = ic."CloneNo"
ORDER BY ic."RefNo", ic."CaseNo", ic."InvNo", ic."CloneNo";