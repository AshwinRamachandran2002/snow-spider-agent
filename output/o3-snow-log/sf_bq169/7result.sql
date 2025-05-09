/*---------------------------------------------------------------
  Retrieve clones that simultaneously show
    1)  chr13  LOSS  overlapping  48 303 751-48 481 890
    2)  chr17  LOSS  overlapping   7 668 421- 7 687 490
    3)  chr11  GAIN  overlapping 108 223 067-108 369 102
  For every such clone list the three matching segments together
  with the corresponding short karyotype description.
----------------------------------------------------------------*/

WITH matching_clones AS (          -- clones fulfilling ALL 3 criteria
    SELECT DISTINCT
           c13."RefNo",
           c13."CaseNo",
           c13."InvNo",
           c13."Clone"
    FROM   MITELMAN.PROD.CYTOCONVERTED c13
    JOIN   MITELMAN.PROD.CYTOCONVERTED c17
           ON  c13."RefNo"  = c17."RefNo"
           AND c13."CaseNo" = c17."CaseNo"
           AND c13."InvNo"  = c17."InvNo"
           AND c13."Clone"  = c17."Clone"
    JOIN   MITELMAN.PROD.CYTOCONVERTED c11
           ON  c13."RefNo"  = c11."RefNo"
           AND c13."CaseNo" = c11."CaseNo"
           AND c13."InvNo"  = c11."InvNo"
           AND c13."Clone"  = c11."Clone"
    WHERE  c13."ChrOrd" = 13        -- chr13 loss
      AND  c13."Type"   = 'Loss'
      AND  c13."Start" <= 48481890
      AND  c13."End"   >= 48303751
      AND  c17."ChrOrd" = 17        -- chr17 loss
      AND  c17."Type"   = 'Loss'
      AND  c17."Start" <= 7687490
      AND  c17."End"   >= 7668421
      AND  c11."ChrOrd" = 11        -- chr11 gain
      AND  c11."Type"   = 'Gain'
      AND  c11."Start" <= 108369102
      AND  c11."End"   >= 108223067
),
selected_segments AS (             -- the three relevant segments per clone
    SELECT
           mc."RefNo",
           mc."CaseNo",
           mc."InvNo",
           mc."Clone",
           seg."ChrOrd",
           seg."Start",
           seg."End",
           seg."Type"
    FROM   matching_clones mc
    JOIN   MITELMAN.PROD.CYTOCONVERTED seg
           ON  seg."RefNo"  = mc."RefNo"
           AND seg."CaseNo" = mc."CaseNo"
           AND seg."InvNo"  = mc."InvNo"
           AND seg."Clone"  = mc."Clone"
    WHERE (
              seg."ChrOrd" = 13 AND seg."Type" = 'Loss'
              AND seg."Start" <= 48481890 AND seg."End" >= 48303751
          ) OR (
              seg."ChrOrd" = 17 AND seg."Type" = 'Loss'
              AND seg."Start" <= 7687490  AND seg."End" >= 7668421
          ) OR (
              seg."ChrOrd" = 11 AND seg."Type" = 'Gain'
              AND seg."Start" <= 108369102 AND seg."End" >= 108223067
          )
)

SELECT
       ss."RefNo",
       ss."CaseNo",
       ss."InvNo",
       ss."Clone"        AS "CloneNo",
       ss."ChrOrd",
       ss."Start",
       ss."End",
       ss."Type",
       kc."CloneShort"   AS "Karyotype_Short"
FROM   selected_segments ss
LEFT JOIN MITELMAN.PROD.KARYCLONE kc
       ON  kc."RefNo"   = ss."RefNo"
       AND kc."CaseNo"  = ss."CaseNo"
       AND kc."InvNo"   = ss."InvNo"
       AND kc."CloneNo" = ss."Clone"
ORDER BY
       ss."RefNo",
       ss."CaseNo",
       ss."InvNo",
       ss."Clone",
       ss."ChrOrd";