/*  Chromosomal copy-number landscape for breast carcinoma (morph = 3111) 
    and breast adenocarcinoma (topo = 0401)                        */

WITH cohort AS (               -- all publications that belong to the cohort
    SELECT DISTINCT "RefNo"
    FROM MITELMAN.PROD.CYTOGEN
    WHERE "Morph" = '3111'      -- breast carcinoma
       OR "Topo"  = '0401'      -- adenocarcinoma of breast
),

cnv AS (                       -- copy-number segments for the cohort
    SELECT  cv."RefNo",
            cv."Chr",
            cv."Start",
            cv."End",
            cv."Type"
    FROM  MITELMAN.PROD.CYTOCONVERTED  cv
    JOIN  cohort                       c   ON cv."RefNo" = c."RefNo"
),

band_map AS (                  -- map every segment to its cytoband
    SELECT  b."chromosome",
            b."cytoband_name",
            b."hg38_start",
            b."hg38_stop",
            cnv."Type"
    FROM  cnv
    JOIN  MITELMAN.PROD.CYTOBANDS_HG38  b
          ON  cnv."Chr"   = b."chromosome"
         AND cnv."Start" >= b."hg38_start"
         AND cnv."End"   <= b."hg38_stop"
),

band_counts AS (               -- raw counts per band
    SELECT  "chromosome",
            "cytoband_name",
            "hg38_start",
            "hg38_stop",
            SUM(CASE WHEN "Type" = 'Amplification'       THEN 1 ELSE 0 END) AS n_amplification,
            SUM(CASE WHEN "Type" = 'Gain'                THEN 1 ELSE 0 END) AS n_gain,
            SUM(CASE WHEN "Type" = 'Loss'                THEN 1 ELSE 0 END) AS n_loss,
            SUM(CASE WHEN "Type" = 'HomozygousDeletion'  THEN 1 ELSE 0 END) AS n_homo_del
    FROM band_map
    GROUP BY "chromosome", "cytoband_name", "hg38_start", "hg38_stop"
),

totals AS (                    -- cohort-wide totals for every class
    SELECT  SUM(n_amplification)  AS total_amplification,
            SUM(n_gain)           AS total_gain,
            SUM(n_loss)           AS total_loss,
            SUM(n_homo_del)       AS total_homo_del
    FROM band_counts
)

SELECT
    bc."chromosome",
    bc."cytoband_name",
    bc.n_amplification                                                AS "n_amplification",
    ROUND(bc.n_amplification * 100.0 / NULLIF(t.total_amplification,0), 2) AS "pct_amplification",
    bc.n_gain                                                         AS "n_gain",
    ROUND(bc.n_gain * 100.0 / NULLIF(t.total_gain,0), 2)              AS "pct_gain",
    bc.n_loss                                                         AS "n_loss",
    ROUND(bc.n_loss * 100.0 / NULLIF(t.total_loss,0), 2)              AS "pct_loss",
    bc.n_homo_del                                                     AS "n_homo_del",
    ROUND(bc.n_homo_del * 100.0 / NULLIF(t.total_homo_del,0), 2)      AS "pct_homo_del"
FROM band_counts  bc
JOIN totals       t  ON 1 = 1           -- bring in cohort totals as constants
ORDER BY
    CASE                                        -- numeric chromosome order
        WHEN bc."chromosome" = 'chrX' THEN 23
        WHEN bc."chromosome" = 'chrY' THEN 24
        ELSE TO_NUMBER(REGEXP_REPLACE(bc."chromosome", 'chr', ''))
    END,
    bc."hg38_start";                            -- left-to-right along chromosome