/*  Chromosomal-band alteration profile for
    – breast carcinoma (Morph = ‘3111’) and
    – adenocarcinoma of the breast (Topo = ‘0401’)
    ----------------------------------------------------------
    For every hg38 cytoband:
      Amp_N      … # of amplifications   (Type = 'Amp')
      Gain_N     … # of single-copy gains (Type = 'Gain')
      Loss_N     … # of single-copy losses (Type = 'Loss')
      HomDel_N   … # of homozygous deletions (Type = 'HomLoss')
      Total      … # of examined clones that overlap the band
      Amp_% … HomDel_%  … percentages with two decimals
*/
WITH cohort AS (   -- 1)  all clones of the requested tumour cohort
    SELECT  cv."RefNo",
            cv."CaseNo",
            cv."InvNo",
            cv."Clone",
            cv."Chr",
            cv."Start",
            cv."End",
            cv."Type"
    FROM    MITELMAN.PROD.CYTOCONVERTED  cv
    JOIN    MITELMAN.PROD.CYTOGEN        cg
      ON    cv."RefNo"  = cg."RefNo"
      AND   cv."CaseNo" = cg."CaseNo"
    WHERE   cg."Morph" = '3111'          -- breast cancer
       OR   cg."Topo"  = '0401'          -- breast adenocarcinoma
),                                         
overlap AS (  -- 2)  overlap each clone-interval with hg38 cytobands
    SELECT  bd."chromosome",
            bd."hg38_start",
            bd."hg38_stop",
            bd."cytoband_name"        AS "Band",
            ch."RefNo",
            ch."CaseNo",
            ch."InvNo",
            ch."Clone",
            ch."Type"
    FROM    cohort                       ch
    JOIN    MITELMAN.PROD.CYTOBANDS_HG38 bd
      ON    bd."chromosome" = ch."Chr"
      AND   bd."hg38_start" < ch."End"   -- interval overlaps band
      AND   bd."hg38_stop"  > ch."Start"
)
SELECT  o."chromosome",
        o."hg38_start",
        o."hg38_stop",
        o."Band",
        /* absolute counts of each alteration class */
        SUM(CASE WHEN o."Type" = 'Amp'     THEN 1 ELSE 0 END)               AS "Amp_N",
        SUM(CASE WHEN o."Type" = 'Gain'    THEN 1 ELSE 0 END)               AS "Gain_N",
        SUM(CASE WHEN o."Type" = 'Loss'    THEN 1 ELSE 0 END)               AS "Loss_N",
        SUM(CASE WHEN o."Type" = 'HomLoss' THEN 1 ELSE 0 END)               AS "HomDel_N",
        /* denominator: distinct clones examined in that band */
        COUNT(DISTINCT CONCAT(o."RefNo",':',o."CaseNo",':',o."InvNo",':',o."Clone")) AS "Total",
        /* percentages – rounded to two decimals */
        ROUND(
              100 * SUM(CASE WHEN o."Type" = 'Amp' THEN 1 ELSE 0 END)
                  / NULLIF( COUNT(DISTINCT CONCAT(o."RefNo",':',o."CaseNo",':',o."InvNo",':',o."Clone")), 0)
        , 2)  AS "Amp_%",
        ROUND(
              100 * SUM(CASE WHEN o."Type" = 'Gain' THEN 1 ELSE 0 END)
                  / NULLIF( COUNT(DISTINCT CONCAT(o."RefNo",':',o."CaseNo",':',o."InvNo",':',o."Clone")), 0)
        , 2)  AS "Gain_%",
        ROUND(
              100 * SUM(CASE WHEN o."Type" = 'Loss' THEN 1 ELSE 0 END)
                  / NULLIF( COUNT(DISTINCT CONCAT(o."RefNo",':',o."CaseNo",':',o."InvNo",':',o."Clone")), 0)
        , 2)  AS "Loss_%",
        ROUND(
              100 * SUM(CASE WHEN o."Type" = 'HomLoss' THEN 1 ELSE 0 END)
                  / NULLIF( COUNT(DISTINCT CONCAT(o."RefNo",':',o."CaseNo",':',o."InvNo",':',o."Clone")), 0)
        , 2)  AS "HomDel_%"
FROM    overlap  o
GROUP BY
        o."chromosome",
        o."hg38_start",
        o."hg38_stop",
        o."Band"
ORDER BY
        /* numeric chromosome order (1-22,X,Y) using regexp to extract number;
           fallback large number for X/Y to keep them at the end           */
        TRY_TO_NUMBER(REGEXP_SUBSTR(o."chromosome",'\\d+')) NULLS FIRST,
        CASE WHEN o."chromosome" ILIKE '%X' THEN 23
             WHEN o."chromosome" ILIKE '%Y' THEN 24
        END,
        o."hg38_start",
        o."hg38_stop";