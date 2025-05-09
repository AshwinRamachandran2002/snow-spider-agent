/*  Clones that show:  
    1) chr-13 Loss overlapping 48 303 751-48 481 890  
    2) chr-17 Loss overlapping 7 668 421-7 687 490  
    3) chr-11 Gain overlapping 108 223 067-108 369 102                                 */

WITH candidate_clones AS (
    /* clones that satisfy ALL THREE alterations */
    SELECT DISTINCT
           c13."RefNo",
           c13."CaseNo",
           c13."InvNo",
           c13."Clone"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED" c13
    JOIN "MITELMAN"."PROD"."CYTOCONVERTED" c17
      ON  c17."RefNo"  = c13."RefNo"
      AND c17."CaseNo" = c13."CaseNo"
      AND c17."InvNo"  = c13."InvNo"
      AND c17."Clone"  = c13."Clone"
    JOIN "MITELMAN"."PROD"."CYTOCONVERTED" c11
      ON  c11."RefNo"  = c13."RefNo"
      AND c11."CaseNo" = c13."CaseNo"
      AND c11."InvNo"  = c13."InvNo"
      AND c11."Clone"  = c13."Clone"
    WHERE c13."ChrOrd" = 13
      AND c13."Type"  ILIKE '%loss%'
      AND c13."Start" <= 48481890
      AND c13."End"   >= 48303751

      AND c17."ChrOrd" = 17
      AND c17."Type"  ILIKE '%loss%'
      AND c17."Start" <= 7687490
      AND c17."End"   >= 7668421

      AND c11."ChrOrd" = 11
      AND c11."Type"  ILIKE '%gain%'
      AND c11."Start" <= 108369102
      AND c11."End"   >= 108223067
),

region_details AS (
    /* pull the three breakpoint rows for each qualifying clone */
    SELECT
        m."RefNo",
        m."CaseNo",
        m."InvNo",
        m."Clone",
        m."ChrOrd",
        m."Start",
        m."End"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED" m
    JOIN candidate_clones cc
      ON  cc."RefNo"  = m."RefNo"
      AND cc."CaseNo" = m."CaseNo"
      AND cc."InvNo"  = m."InvNo"
      AND cc."Clone"  = m."Clone"
    WHERE (m."ChrOrd" = 13 AND m."Type" ILIKE '%loss%'  AND m."Start" <= 48481890 AND m."End" >= 48303751)
       OR (m."ChrOrd" = 17 AND m."Type" ILIKE '%loss%'  AND m."Start" <= 7687490  AND m."End" >= 7668421 )
       OR (m."ChrOrd" = 11 AND m."Type" ILIKE '%gain%'  AND m."Start" <= 108369102 AND m."End" >= 108223067)
)

SELECT
    cc."RefNo",
    cc."CaseNo",
    cc."InvNo",
    cc."Clone",

    /* chr-13 loss details */
    MAX(CASE WHEN rd."ChrOrd" = 13 THEN rd."ChrOrd" END) AS "Chr13_ChrOrd",
    MAX(CASE WHEN rd."ChrOrd" = 13 THEN rd."Start"  END) AS "Chr13_Start",
    MAX(CASE WHEN rd."ChrOrd" = 13 THEN rd."End"    END) AS "Chr13_End",

    /* chr-17 loss details */
    MAX(CASE WHEN rd."ChrOrd" = 17 THEN rd."ChrOrd" END) AS "Chr17_ChrOrd",
    MAX(CASE WHEN rd."ChrOrd" = 17 THEN rd."Start"  END) AS "Chr17_Start",
    MAX(CASE WHEN rd."ChrOrd" = 17 THEN rd."End"    END) AS "Chr17_End",

    /* chr-11 gain details */
    MAX(CASE WHEN rd."ChrOrd" = 11 THEN rd."ChrOrd" END) AS "Chr11_ChrOrd",
    MAX(CASE WHEN rd."ChrOrd" = 11 THEN rd."Start"  END) AS "Chr11_Start",
    MAX(CASE WHEN rd."ChrOrd" = 11 THEN rd."End"    END) AS "Chr11_End",

    kc."CloneShort"
FROM       candidate_clones cc
JOIN       region_details rd
       ON  rd."RefNo"  = cc."RefNo"
      AND  rd."CaseNo" = cc."CaseNo"
      AND  rd."InvNo"  = cc."InvNo"
      AND  rd."Clone"  = cc."Clone"
LEFT JOIN "MITELMAN"."PROD"."KARYCLONE" kc
       ON kc."RefNo"   = cc."RefNo"
      AND kc."CaseNo"  = cc."CaseNo"
      AND kc."InvNo"   = cc."InvNo"
      AND kc."CloneNo" = cc."Clone"
GROUP BY
    cc."RefNo",
    cc."CaseNo",
    cc."InvNo",
    cc."Clone",
    kc."CloneShort"
ORDER BY
    cc."RefNo",
    cc."CaseNo",
    cc."InvNo",
    cc."Clone";