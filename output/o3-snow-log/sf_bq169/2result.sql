WITH flags AS (        -- mark each clone that contains the three required alterations
    SELECT
        "RefNo",
        "CaseNo",
        "InvNo",
        "Clone",
        MAX(CASE WHEN "Chr" = 'chr13'
                 AND "Type" ILIKE '%loss%'
                 AND "Start" <= 48303751
                 AND "End"   >= 48481890 THEN 1 ELSE 0 END) AS has_chr13_loss,
        MAX(CASE WHEN "Chr" = 'chr17'
                 AND "Type" ILIKE '%loss%'
                 AND "Start" <= 7668421
                 AND "End"   >= 7687490  THEN 1 ELSE 0 END) AS has_chr17_loss,
        MAX(CASE WHEN "Chr" = 'chr11'
                 AND "Type" ILIKE '%gain%'
                 AND "Start" <= 108223067
                 AND "End"   >= 108369102 THEN 1 ELSE 0 END) AS has_chr11_gain
    FROM MITELMAN.PROD.CYTOCONVERTED
    GROUP BY "RefNo","CaseNo","InvNo","Clone"
),
hits AS (               -- keep only clones that have all three alterations
    SELECT "RefNo","CaseNo","InvNo","Clone"
    FROM   flags
    WHERE  has_chr13_loss = 1
       AND has_chr17_loss = 1
       AND has_chr11_gain = 1
),
chr13_detail AS (       -- coordinates for the chr13 loss
    SELECT
        "RefNo","CaseNo","InvNo","Clone",
        MIN("ChrOrd") AS "Chr13_ChrOrd",
        MIN("Start")  AS "Chr13_Start",
        MAX("End")    AS "Chr13_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "Chr" = 'chr13'
      AND "Type" ILIKE '%loss%'
      AND "Start" <= 48303751
      AND "End"   >= 48481890
    GROUP BY "RefNo","CaseNo","InvNo","Clone"
),
chr17_detail AS (       -- coordinates for the chr17 loss
    SELECT
        "RefNo","CaseNo","InvNo","Clone",
        MIN("ChrOrd") AS "Chr17_ChrOrd",
        MIN("Start")  AS "Chr17_Start",
        MAX("End")    AS "Chr17_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "Chr" = 'chr17'
      AND "Type" ILIKE '%loss%'
      AND "Start" <= 7668421
      AND "End"   >= 7687490
    GROUP BY "RefNo","CaseNo","InvNo","Clone"
),
chr11_detail AS (       -- coordinates for the chr11 gain
    SELECT
        "RefNo","CaseNo","InvNo","Clone",
        MIN("ChrOrd") AS "Chr11_ChrOrd",
        MIN("Start")  AS "Chr11_Start",
        MAX("End")    AS "Chr11_End"
    FROM MITELMAN.PROD.CYTOCONVERTED
    WHERE "Chr" = 'chr11'
      AND "Type" ILIKE '%gain%'
      AND "Start" <= 108223067
      AND "End"   >= 108369102
    GROUP BY "RefNo","CaseNo","InvNo","Clone"
)
SELECT DISTINCT
    h."RefNo",
    h."CaseNo",
    h."InvNo",
    h."Clone"            AS "CloneNo",
    c13."Chr13_ChrOrd",
    c13."Chr13_Start",
    c13."Chr13_End",
    c17."Chr17_ChrOrd",
    c17."Chr17_Start",
    c17."Chr17_End",
    c11."Chr11_ChrOrd",
    c11."Chr11_Start",
    c11."Chr11_End",
    kc."CloneShort"
FROM hits h
JOIN chr13_detail c13
  ON c13."RefNo"  = h."RefNo"
 AND c13."CaseNo" = h."CaseNo"
 AND c13."InvNo"  = h."InvNo"
 AND c13."Clone"  = h."Clone"
JOIN chr17_detail c17
  ON c17."RefNo"  = h."RefNo"
 AND c17."CaseNo" = h."CaseNo"
 AND c17."InvNo"  = h."InvNo"
 AND c17."Clone"  = h."Clone"
JOIN chr11_detail c11
  ON c11."RefNo"  = h."RefNo"
 AND c11."CaseNo" = h."CaseNo"
 AND c11."InvNo"  = h."InvNo"
 And c11."Clone"  = h."Clone"
LEFT JOIN MITELMAN.PROD.KARYCLONE kc
  ON kc."RefNo"    = h."RefNo"
 AND kc."CaseNo"   = h."CaseNo"
 AND kc."InvNo"    = h."InvNo"
 AND kc."CloneNo"  = h."Clone"
ORDER BY h."RefNo", h."CaseNo", h."InvNo", h."Clone";