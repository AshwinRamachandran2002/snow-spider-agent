/*  Cohort-wide frequencies of copy-number changes per hg38 cytoband
    – breast-cancer  (Morph = 3111)  OR  adenocarcinoma  (Topo = 0401)
---------------------------------------------------------------------*/
WITH cohort AS (      -- every unique sample in the study
    SELECT DISTINCT
           cc."RefNo" || '-' || cc."CaseNo" || '-' || cc."InvNo" AS sid
    FROM   MITELMAN.PROD.CYTOCONVERTED cc
    JOIN   MITELMAN.PROD.CYTOGEN      cg
           ON  cg."RefNo"  = cc."RefNo"
           AND cg."CaseNo" = cc."CaseNo"
    WHERE  cg."Morph" = '3111'    -- breast cancer
       OR  cg."Topo"  = '0401'    -- adenocarcinoma
),
band_events AS (      -- copy-number events mapped to hg38 cytobands
    SELECT
        b."chromosome",
        b."cytoband_name",
        b."hg38_start",
        cc."Type",
        cc."RefNo" || '-' || cc."CaseNo" || '-' || cc."InvNo" AS sid
    FROM   MITELMAN.PROD.CYTOCONVERTED   cc
    JOIN   MITELMAN.PROD.CYTOGEN         cg
           ON  cg."RefNo"  = cc."RefNo"
           AND cg."CaseNo" = cc."CaseNo"
    JOIN   MITELMAN.PROD.CYTOBANDS_HG38  b
           ON  b."chromosome"  = cc."Chr"
           AND b."hg38_start" <= cc."End"
           AND b."hg38_stop"  >= cc."Start"
    WHERE  cg."Morph" = '3111'
       OR  cg."Topo"  = '0401'
)
SELECT
    be."chromosome",
    be."cytoband_name",

    /* ---- absolute counts ---- */
    COUNT(DISTINCT CASE WHEN be."Type" = 'Amplification'                                   THEN be.sid END) AS "Amplifications",
    COUNT(DISTINCT CASE WHEN be."Type" = 'Gain'                                            THEN be.sid END) AS "Gains",
    COUNT(DISTINCT CASE WHEN be."Type" = 'Loss'                                            THEN be.sid END) AS "Losses",
    COUNT(DISTINCT CASE WHEN be."Type" IN ('HomLoss','HomozygousDeletion','HomDel')        THEN be.sid END) AS "HomDel",

    /* ---- cohort frequencies ( % with two decimals ) ---- */
    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN be."Type" = 'Amplification' THEN be.sid END)
        / (SELECT COUNT(*) FROM cohort)
    , 2) AS "Amplifications_%",

    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN be."Type" = 'Gain'          THEN be.sid END)
        / (SELECT COUNT(*) FROM cohort)
    , 2) AS "Gains_%",

    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN be."Type" = 'Loss'          THEN be.sid END)
        / (SELECT COUNT(*) FROM cohort)
    , 2) AS "Losses_%",

    ROUND(
        100.0 * COUNT(DISTINCT CASE WHEN be."Type" IN ('HomLoss','HomozygousDeletion','HomDel') THEN be.sid END)
        / (SELECT COUNT(*) FROM cohort)
    , 2) AS "HomDel_%"

FROM       band_events  be
GROUP BY   be."chromosome", be."cytoband_name", be."hg38_start"

/* ---- genomic ordering: numeric chr 1-22 followed by chrX, chrY ---- */
ORDER BY
    CASE
        WHEN be."chromosome" = 'chrX' THEN 23
        WHEN be."chromosome" = 'chrY' THEN 24
        ELSE TO_NUMBER(REPLACE(be."chromosome", 'chr', ''))
    END,
    be."hg38_start";