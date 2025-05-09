/*  Copy-number frequency per cytogenetic band in
    breast-cancer (morph = '3111') and adenocarcinoma (topo = '0401') cases  */

WITH cohort AS (      -- every investigated sample (RefNo-CaseNo-InvNo triple)
    SELECT DISTINCT
           c."RefNo",
           c."CaseNo",
           c."InvNo"
    FROM   MITELMAN.PROD.CYTOCONVERTED  c
    JOIN   MITELMAN.PROD.CYTOGEN        g
           ON  c."RefNo"  = g."RefNo"
           AND c."CaseNo" = g."CaseNo"
    WHERE  g."Morph" = '3111'
       OR  g."Topo"  = '0401'
),
tot AS (              -- cohort size
    SELECT COUNT(*) AS total_cases
    FROM   cohort
),

segments AS (         -- all CytoConverter segments that belong to the cohort
    SELECT c."RefNo",
           c."CaseNo",
           c."InvNo",
           c."Type",          -- Amplification / Gain / Loss / HomDel
           c."Chr",
           c."Start",
           c."End"
    FROM   MITELMAN.PROD.CYTOCONVERTED c
    JOIN   cohort h
           ON  c."RefNo"  = h."RefNo"
           AND c."CaseNo" = h."CaseNo"
           AND c."InvNo"  = h."InvNo"
),

mapped AS (           -- overlap every segment with every cytoband it intersects
    SELECT DISTINCT
           s."RefNo",
           s."CaseNo",
           s."InvNo",
           s."Type",
           b."chromosome",
           b."cytoband_name"  AS "Band",
           b."hg38_start"     AS "Band_Start",
           b."hg38_stop"      AS "Band_Stop"
    FROM   segments s
    JOIN   MITELMAN.PROD.CYTOBANDS_HG38 b
           ON  s."Chr"   = b."chromosome"
           AND s."Start" <= b."hg38_stop"
           AND s."End"   >= b."hg38_start"
),

aggregated AS (       -- counts of unique samples per band & copy-number class
    SELECT
        m."chromosome",
        m."Band",
        m."Band_Start",
        m."Band_Stop",

        COUNT(DISTINCT CASE WHEN m."Type" = 'Amplification'
                            THEN m."RefNo"||'-'||m."CaseNo"||'-'||m."InvNo" END) AS n_amp,

        COUNT(DISTINCT CASE WHEN m."Type" = 'Gain'
                            THEN m."RefNo"||'-'||m."CaseNo"||'-'||m."InvNo" END) AS n_gain,

        COUNT(DISTINCT CASE WHEN m."Type" = 'Loss'
                            THEN m."RefNo"||'-'||m."CaseNo"||'-'||m."InvNo" END) AS n_loss,

        COUNT(DISTINCT CASE WHEN m."Type" = 'HomDel'
                            THEN m."RefNo"||'-'||m."CaseNo"||'-'||m."InvNo" END) AS n_homdel
    FROM   mapped m
    GROUP  BY m."chromosome", m."Band", m."Band_Start", m."Band_Stop"
)

/*  final result: counts + frequencies (%) with two decimals            */
SELECT
       a."chromosome"                               AS "Chr",
       a."Band",
       a."Band_Start",
       a."Band_Stop",

       a.n_amp                                      AS "Amp_Cases",
       ROUND(100.0 * a.n_amp    / t.total_cases, 2) AS "Amp_%",

       a.n_gain                                     AS "Gain_Cases",
       ROUND(100.0 * a.n_gain   / t.total_cases, 2) AS "Gain_%",

       a.n_loss                                     AS "Loss_Cases",
       ROUND(100.0 * a.n_loss   / t.total_cases, 2) AS "Loss_%",

       a.n_homdel                                   AS "HomDel_Cases",
       ROUND(100.0 * a.n_homdel / t.total_cases, 2) AS "HomDel_%"
FROM   aggregated a
CROSS  JOIN tot t
ORDER  BY
       CASE
           WHEN a."chromosome" = 'chrX' THEN 23
           WHEN a."chromosome" = 'chrY' THEN 24
           ELSE TO_NUMBER(REPLACE(a."chromosome",'chr',''))
       END,
       a."Band_Start",
       a."Band_Stop";