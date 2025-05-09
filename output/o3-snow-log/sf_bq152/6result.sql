/* -----------------------------------------------------------------
   Chromosome-arm (“p” / “q”) CNV profile for TCGA-BRCA
   ‑ overlap-weighted mean copy number per (case , arm)
   ‑ rounded CN mapped to 5 CNV classes
   ‑ frequency of each class across all BRCA cases
   ----------------------------------------------------------------*/
WITH
/* 1.  All BRCA copy-number segments --------------------------------*/
brca_segments AS (
    SELECT  "case_barcode",
            "chromosome",
            CAST("start_pos" AS NUMBER) AS seg_start,
            CAST("end_pos"   AS NUMBER) AS seg_end,
            "segment_mean"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE   "project_short_name" = 'TCGA-BRCA'
),

/* 2.  Chromosome lengths (max end-pos observed) --------------------*/
chr_len AS (
    SELECT  "chromosome",
            MAX(seg_end) AS chr_len
    FROM    brca_segments
    GROUP BY "chromosome"
),

/* 3.  Construct simple “cytoband” table = p- and q-arms ------------*/
cyto_arm AS (
    SELECT  "chromosome",
            CONCAT("chromosome", 'p')            AS cytoband_name,
            1                                    AS band_start,
            FLOOR(chr_len / 2)                   AS band_end
    FROM    chr_len
    UNION ALL
    SELECT  "chromosome",
            CONCAT("chromosome", 'q')            AS cytoband_name,
            FLOOR(chr_len / 2) + 1               AS band_start,
            chr_len                              AS band_end
    FROM    chr_len
),

/* 4.  Overlap between segments and arms ---------------------------*/
ovl AS (
    SELECT  c.cytoband_name,
            c.band_start,
            c.band_end,
            s."case_barcode",
            LEAST(s.seg_end , c.band_end)
        -   GREATEST(s.seg_start , c.band_start) + 1      AS ov_len,
            2 * POWER(2, s."segment_mean")                AS seg_cn   -- CN = 2 × 2^log2R
    FROM    brca_segments s
    JOIN    cyto_arm      c
      ON    c."chromosome" = s."chromosome"
     AND    s.seg_end   >= c.band_start
     AND    s.seg_start <= c.band_end
),

/* 5.  Overlap-weighted mean CN per (case , arm) -------------------*/
arm_case_cn AS (
    SELECT  cytoband_name,
            band_start,
            band_end,
            "case_barcode",
            ROUND( SUM(seg_cn * ov_len) / NULLIF(SUM(ov_len), 0) ) AS rounded_cn
    FROM    ovl
    GROUP BY cytoband_name, band_start, band_end, "case_barcode"
),

/* 6.  Map rounded CN to CNV class --------------------------------*/
arm_case_class AS (
    SELECT  cytoband_name,
            band_start,
            band_end,
            "case_barcode",
            CASE rounded_cn
                 WHEN 0 THEN 'Homozygous Deletion'
                 WHEN 1 THEN 'Heterozygous Deletion'
                 WHEN 2 THEN 'Diploid'
                 WHEN 3 THEN 'Gain'
                 ELSE        'Amplification'          -- rounded_cn > 3
            END AS cnv_type
    FROM    arm_case_cn
),

/* 7.  Frequency of each class per arm ----------------------------*/
arm_freq AS (
    SELECT  cytoband_name,
            band_start,
            band_end,
            SUM(CASE WHEN cnv_type = 'Homozygous Deletion'   THEN 1 ELSE 0 END) AS homdel_cnt,
            SUM(CASE WHEN cnv_type = 'Heterozygous Deletion' THEN 1 ELSE 0 END) AS hetdel_cnt,
            SUM(CASE WHEN cnv_type = 'Diploid'              THEN 1 ELSE 0 END) AS diploid_cnt,
            SUM(CASE WHEN cnv_type = 'Gain'                 THEN 1 ELSE 0 END) AS gain_cnt,
            SUM(CASE WHEN cnv_type = 'Amplification'        THEN 1 ELSE 0 END) AS amp_cnt,
            COUNT(*) AS case_cnt
    FROM    arm_case_class
    GROUP BY cytoband_name, band_start, band_end
),

/* 8.  Total BRCA case count --------------------------------------*/
n_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS tot_cases
    FROM   brca_segments
)

/* 9.  Final report ------------------------------------------------*/
SELECT  f.cytoband_name AS "CYTOBAND",
        f.band_start    AS "BAND_START",
        f.band_end      AS "BAND_END",
        ROUND(100.0 * f.homdel_cnt / n.tot_cases , 2) AS "HOMDEL_%",
        ROUND(100.0 * f.hetdel_cnt / n.tot_cases , 2) AS "HETDEL_%",
        ROUND(100.0 * f.diploid_cnt / n.tot_cases , 2) AS "DIPLOID_%",
        ROUND(100.0 * f.gain_cnt    / n.tot_cases , 2) AS "GAIN_%",
        ROUND(100.0 * f.amp_cnt     / n.tot_cases , 2) AS "AMPLIFICATION_%"
FROM    arm_freq f
CROSS   JOIN n_cases n
ORDER BY f.cytoband_name;