/*--------------------------------------------------------------
 Purpose :   For the combined cohort of
              • breast-cancer samples           (Morphology = 3111)
              • adenocarcinoma samples          (Topography = 0401)
            count CytoConverter events that overlap every
            cytogenetic band and classify them into
              – Amplification      (Gain, ≥ 2 extra chromosomes)
              – Gain               (Gain, exactly 1 extra)
              – Loss               (Loss, exactly −1)
              – HomDel             (Loss, ≤ −2 chromosomes)
            then report both the counts and their cohort-wide
            percentages (2 decimal places).  
            Result is ordered by chromosome ordinal and band
            genomic start/stop.
----------------------------------------------------------------*/
WITH cohort_events AS (          -- 1.  events belonging to the cohort
    SELECT  cc."RefNo",
            cc."CaseNo",
            cc."InvNo",
            cc."Clone"                       AS "CloneNo",
            cc."Chr",
            cc."Start",
            cc."End",
            cc."Type",                      -- Gain / Loss
            kc."ChromoMin",
            kc."ChromoMax"
    FROM   MITELMAN.PROD.CYTOCONVERTED  cc
    JOIN   MITELMAN.PROD.CYTOGEN        cg
           ON  cg."RefNo"  = cc."RefNo"
           AND cg."CaseNo" = cc."CaseNo"
    LEFT JOIN MITELMAN.PROD.KARYCLONE   kc   -- copy-number proxy
           ON  kc."RefNo"   = cc."RefNo"
           AND kc."CaseNo"  = cc."CaseNo"
           AND kc."InvNo"   = cc."InvNo"
           AND kc."CloneNo" = cc."Clone"
    WHERE  cg."Morph" = '3111'                -- breast cancer
       OR  cg."Topo"  = '0401'                -- adenocarcinoma
),                                           
classified AS (               -- 2.  add event class label
    SELECT  ce.*,
            CASE
                 WHEN ce."Type" = 'Gain'
                      AND ce."ChromoMax" >= 48          THEN 'Amplification'
                 WHEN ce."Type" = 'Gain'                THEN 'Gain'
                 WHEN ce."Type" = 'Loss'
                      AND ce."ChromoMin" <= 44          THEN 'HomDel'
                 ELSE 'Loss'
            END AS event_class
    FROM    cohort_events ce
),                                           
band_events AS (            -- 3.  map events to cytogenetic bands
    SELECT  cb."chromosome"                     AS chr,
            cb."cytoband_name",
            cb."hg38_start",
            cb."hg38_stop",
            c.event_class
    FROM   classified               c
    JOIN   MITELMAN.PROD.CYTOBANDS_HG38 cb
           ON  c."Chr"  = cb."chromosome"
           AND c."Start" <= cb."hg38_stop"      -- interval overlap
           AND c."End"   >= cb."hg38_start"
)
/*--------------------------------------------------------------
 4.  Aggregate: counts & cohort-wide percentages
----------------------------------------------------------------*/
SELECT
    chr                          AS "Chr",
    "cytoband_name"              AS "Band",
    "hg38_start"                 AS "Band_Start",
    "hg38_stop"                  AS "Band_Stop",

    /* raw counts ------------------------------------------------*/
    COUNT_IF(event_class = 'Amplification')        AS "N_Amplifications",
    COUNT_IF(event_class = 'Gain')                 AS "N_Gains",
    COUNT_IF(event_class = 'Loss')                 AS "N_Losses",
    COUNT_IF(event_class = 'HomDel')               AS "N_HomoDel",

    /* percentages (2-dp) ---------------------------------------*/
    ROUND(
        100.0 * COUNT_IF(event_class = 'Amplification')
        / NULLIF( SUM(COUNT_IF(event_class = 'Amplification'))
                   OVER () ,0)
    ,2)                                            AS "Pct_Amplifications",
    ROUND(
        100.0 * COUNT_IF(event_class = 'Gain')
        / NULLIF( SUM(COUNT_IF(event_class = 'Gain')) OVER () ,0)
    ,2)                                            AS "Pct_Gains",
    ROUND(
        100.0 * COUNT_IF(event_class = 'Loss')
        / NULLIF( SUM(COUNT_IF(event_class = 'Loss')) OVER () ,0)
    ,2)                                            AS "Pct_Losses",
    ROUND(
        100.0 * COUNT_IF(event_class = 'HomDel')
        / NULLIF( SUM(COUNT_IF(event_class = 'HomDel')) OVER () ,0)
    ,2)                                            AS "Pct_HomoDel"

FROM   band_events
GROUP  BY chr,
          "cytoband_name",
          "hg38_start",
          "hg38_stop"

/*--------------------------------------------------------------
 5.  Sort: chromosome ordinal then band coordinates
----------------------------------------------------------------*/
ORDER BY
    CASE    -- numeric order for chr1-22, X=23, Y=24
        WHEN chr = 'chrX' THEN 23
        WHEN chr = 'chrY' THEN 24
        ELSE TO_NUMBER(SUBSTR(chr,4))
    END,
    "hg38_start",
    "hg38_stop";