/*---------------------------------------------------------------
  Frequency of copy-number events (breast-cancer 3111 + topology 0401)
  ‑ per hg38 cytoband
  ‑ four categories requested – only Gain / Loss exist in the
    CytoConverter output, therefore “Amplification” and “HomDel”
    are returned as zeroes.
----------------------------------------------------------------*/
WITH cohort_samples AS (              -- all cases that belong to one
    SELECT DISTINCT                   -- of the requested diagnoses
           g."RefNo",
           g."CaseNo"
    FROM   MITELMAN.PROD.CYTOGEN g
    WHERE  g."Morph" = '3111'         -- breast cancer
       OR  g."Topo"  = '0401'         -- adenocarcinoma
),

total_samples AS (                    -- denominator for percentages
    SELECT COUNT(*) AS total_n
    FROM   cohort_samples
),

segments AS (                         -- CytoConverter intervals
    SELECT  c."RefNo",
            c."CaseNo",
            c."Type",                 -- Gain / Loss
            c."Chr",
            c."Start",
            c."End"
    FROM    MITELMAN.PROD.CYTOCONVERTED c
    JOIN    cohort_samples s
      ON    c."RefNo" = s."RefNo"
     AND    c."CaseNo" = s."CaseNo"
),

band_hits AS (                        -- map every interval to every
    SELECT DISTINCT                   -- cytoband that it overlaps
           b."chromosome",
           b."cytoband_name",
           b."hg38_start",
           b."hg38_stop",
           s."Type",
           s."RefNo",
           s."CaseNo"
    FROM   segments s
    JOIN   MITELMAN.PROD.CYTOBANDS_HG38 b
      ON   s."Chr"   = b."chromosome"
     AND   s."Start" < b."hg38_stop"  -- overlap test
     AND   s."End"   > b."hg38_start"
)

SELECT
    bh."chromosome"                AS "Chr",
    bh."cytoband_name"             AS "Band",
    bh."hg38_start"                AS "BandStart",
    bh."hg38_stop"                 AS "BandEnd",

    /* ---- 1 extra copy (Gain) -------------------------------- */
    COUNT( DISTINCT CASE WHEN bh."Type" = 'Gain'
                          THEN bh."RefNo"||'-'||bh."CaseNo" END
         )                                 AS "n_gain",
    ROUND(
        COUNT( DISTINCT CASE WHEN bh."Type" = 'Gain'
                              THEN bh."RefNo"||'-'||bh."CaseNo" END
             ) * 100.0 / ts.total_n , 2)   AS "freq_gain_pct",

    /* ---- >1 extra copy (Amplification) – not available ------ */
    0                                       AS "n_amplification",
    0.00                                    AS "freq_amplification_pct",

    /* ---- 1 copy loss --------------------------------------- */
    COUNT( DISTINCT CASE WHEN bh."Type" = 'Loss'
                          THEN bh."RefNo"||'-'||bh."CaseNo" END
         )                                 AS "n_loss",
    ROUND(
        COUNT( DISTINCT CASE WHEN bh."Type" = 'Loss'
                              THEN bh."RefNo"||'-'||bh."CaseNo" END
             ) * 100.0 / ts.total_n , 2)   AS "freq_loss_pct",

    /* ---- 2 copy loss (HomDel) – not available -------------- */
    0                                       AS "n_homdel",
    0.00                                    AS "freq_homdel_pct"

FROM       band_hits  bh
CROSS JOIN total_samples ts

GROUP BY    bh."chromosome",
            bh."cytoband_name",
            bh."hg38_start",
            bh."hg38_stop",
            ts.total_n

ORDER BY    /* first numeric chr, then X,Y */
            CASE WHEN bh."chromosome" = 'chrX' THEN 23
                 WHEN bh."chromosome" = 'chrY' THEN 24
                 ELSE TO_NUMBER( REPLACE(bh."chromosome",'chr','') )
            END,
            bh."hg38_start",
            bh."hg38_stop";