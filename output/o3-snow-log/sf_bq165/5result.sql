/* ---------------------------------------------------------------
   Chromosomal‐band counts & frequencies of CNV categories
   – Cohort: breast-cancer cases (Morph = ‘3111’)   OR
             adenocarcinoma cases (Topo = ‘0401’)
   – CNV categories (taken from CytoConverter “Type” column)
         • Amplification      ( >1 extra copies )
         • Gain               ( +1 copy )
         • Loss               ( –1 copy )
         • HomDel             ( –2 copies = homozygous deletion)
   – Frequencies are percentages (two decimals) within each
     CNV category across the whole cohort.
   – Rows ordered by chromosomal order (1-22,X,Y) and band start.
-----------------------------------------------------------------*/
WITH cohort_segments AS (          -- 1)  select cohort CNV segments
    SELECT  c."RefNo" ,
            c."CaseNo",
            c."Chr"          AS chr,
            c."Start",
            c."End",
            c."Type"
    FROM   MITELMAN.PROD.CYTOCONVERTED  c
    JOIN   MITELMAN.PROD.CYTOGEN        g
           ON  c."RefNo"  = g."RefNo"
           AND c."CaseNo" = g."CaseNo"
    WHERE  (g."Morph" = '3111' OR g."Topo" = '0401')
      AND  c."Type" IN ('Amplification','Gain','Loss','HomDel')
),
segment_midpoint AS (              -- 2)  use the midpoint to map to a single band
    SELECT  cs.*,
            (cs."Start" + cs."End")/2 :: NUMBER AS mid_pos
    FROM    cohort_segments cs
),
band_map AS (                      -- 3)  attach each segment to its cytoband
    SELECT  sm."Type",
            b."chromosome",
            b."cytoband_name",
            b."hg38_start",
            b."hg38_stop"
    FROM    segment_midpoint sm
    JOIN    MITELMAN.PROD.CYTOBANDS_HG38  b
           ON  b."chromosome" = sm.chr
           AND sm.mid_pos BETWEEN b."hg38_start" AND b."hg38_stop"
),
band_counts AS (                   -- 4)  count CNV categories per band
    SELECT  bm."chromosome",
            bm."cytoband_name",
            bm."hg38_start",
            bm."hg38_stop",
            SUM( CASE WHEN bm."Type" = 'Amplification' THEN 1 ELSE 0 END ) AS amplifications,
            SUM( CASE WHEN bm."Type" = 'Gain'          THEN 1 ELSE 0 END ) AS gains,
            SUM( CASE WHEN bm."Type" = 'Loss'          THEN 1 ELSE 0 END ) AS losses,
            SUM( CASE WHEN bm."Type" = 'HomDel'        THEN 1 ELSE 0 END ) AS homdels
    FROM    band_map bm
    GROUP BY bm."chromosome",
             bm."cytoband_name",
             bm."hg38_start",
             bm."hg38_stop"
),
totals AS (                        -- 5)  totals for frequency denominators
    SELECT  SUM(amplifications) AS total_amplifications,
            SUM(gains)          AS total_gains,
            SUM(losses)         AS total_losses,
            SUM(homdels)        AS total_homdels
    FROM    band_counts
),
final AS (                         -- 6)  compute frequencies (%)
    SELECT  bc."chromosome",
            bc."cytoband_name",
            bc."hg38_start",
            bc."hg38_stop",
            bc.amplifications                                    AS n_amplifications,
            ROUND(100 * bc.amplifications / NULLIF(t.total_amplifications,0), 2) AS amplification_pct,
            bc.gains                                             AS n_gains,
            ROUND(100 * bc.gains          / NULLIF(t.total_gains,0),          2) AS gain_pct,
            bc.losses                                            AS n_losses,
            ROUND(100 * bc.losses        / NULLIF(t.total_losses,0),         2) AS loss_pct,
            bc.homdels                                           AS n_homdels,
            ROUND(100 * bc.homdels      / NULLIF(t.total_homdels,0),        2) AS homdel_pct
    FROM    band_counts bc
    CROSS JOIN totals t
)
SELECT  *
FROM    final
ORDER BY 
        /* numeric chromosome ordering 1-22, X (=23), Y (=24) */
        CASE 
            WHEN "chromosome" = 'chrX' THEN 23
            WHEN "chromosome" = 'chrY' THEN 24
            ELSE TO_NUMBER(SUBSTR("chromosome",4))
        END,
        "hg38_start",
        "hg38_stop";