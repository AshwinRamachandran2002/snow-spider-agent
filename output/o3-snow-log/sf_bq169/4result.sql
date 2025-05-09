/*  Clones that have
    – chr13 LOSS   overlapping 48 303 751-48 481 890
    – chr17 LOSS   overlapping  7 668 421- 7 687 490
    – chr11 GAIN   overlapping 108 223 067-108 369 102
    plus the individual alteration rows and their karyotype
*/
WITH chr13_loss AS (          -- clones with the specified chr13 loss
    SELECT DISTINCT "RefNo","CaseNo","InvNo","Clone"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED"
    WHERE "ChrOrd" = 13
      AND "Type"   ILIKE '%Loss%'
      AND "Start" <= 48481890
      AND "End"   >= 48303751
),
chr17_loss AS (               -- clones with the specified chr17 loss
    SELECT DISTINCT "RefNo","CaseNo","InvNo","Clone"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED"
    WHERE "ChrOrd" = 17
      AND "Type"   ILIKE '%Loss%'
      AND "Start" <= 7687490
      AND "End"   >= 7668421
),
chr11_gain AS (               -- clones with the specified chr11 gain
    SELECT DISTINCT "RefNo","CaseNo","InvNo","Clone"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED"
    WHERE "ChrOrd" = 11
      AND "Type"   ILIKE '%Gain%'
      AND "Start" <= 108369102
      AND "End"   >= 108223067
),
matching_clones AS (          -- intersection of the three sets above
    SELECT c13."RefNo",
           c13."CaseNo",
           c13."InvNo",
           c13."Clone"
    FROM chr13_loss c13
    JOIN chr17_loss c17 USING ("RefNo","CaseNo","InvNo","Clone")
    JOIN chr11_gain c11 USING ("RefNo","CaseNo","InvNo","Clone")
),
region_rows AS (              -- the three alteration rows for every matching clone
    SELECT cv."RefNo",
           cv."CaseNo",
           cv."InvNo",
           cv."Clone",
           cv."ChrOrd",
           cv."Start",
           cv."End",
           cv."Type"
    FROM "MITELMAN"."PROD"."CYTOCONVERTED" cv
    JOIN matching_clones mc
      ON mc."RefNo"  = cv."RefNo"
     AND mc."CaseNo" = cv."CaseNo"
     AND mc."InvNo"  = cv."InvNo"
     AND mc."Clone"  = cv."Clone"
    WHERE (cv."ChrOrd" = 13 AND cv."Type" ILIKE '%Loss%' AND cv."Start" <= 48481890 AND cv."End" >= 48303751)
       OR (cv."ChrOrd" = 17 AND cv."Type" ILIKE '%Loss%' AND cv."Start" <= 7687490  AND cv."End" >= 7668421)
       OR (cv."ChrOrd" = 11 AND cv."Type" ILIKE '%Gain%' AND cv."Start" <= 108369102 AND cv."End" >= 108223067)
)
SELECT r."RefNo",
       r."CaseNo",
       r."InvNo",
       r."Clone"      AS "CloneNo",
       r."ChrOrd",
       r."Start",
       r."End",
       r."Type",
       kc."CloneShort"
FROM region_rows r
LEFT JOIN "MITELMAN"."PROD"."KARYCLONE" kc
  ON kc."RefNo"   = r."RefNo"
 AND kc."CaseNo"  = r."CaseNo"
 AND kc."InvNo"   = r."InvNo"
 AND kc."CloneNo" = r."Clone"
ORDER BY r."RefNo",
         r."CaseNo",
         r."InvNo",
         r."Clone",
         r."ChrOrd";