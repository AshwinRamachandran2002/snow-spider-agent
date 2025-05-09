WITH kirc_segs AS (   -- KIRC segment‑level copy number data
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
), 
bands AS (            -- cytogenetic band co‑ordinates
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
), 
seg_band_overlap AS ( -- keep only segments that overlap a band
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        s."copy_number"
    FROM kirc_segs s
    JOIN bands   b
      ON s."chromosome" = b."chromosome"
     AND GREATEST(s."start_pos", b."hg38_start")
       < LEAST  (s."end_pos"  , b."hg38_stop")
), 
case_band_cn AS (     -- maximum copy number per case & band
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        MAX("copy_number") AS max_cn
    FROM seg_band_overlap
    GROUP BY
        "case_barcode",
        "chromosome",
        "cytoband_name"
), 
case_band_class AS (  -- classify copy number states
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN max_cn > 3 THEN 'Amplification'
            WHEN max_cn = 3 THEN 'Gain'
            WHEN max_cn = 2 THEN 'Normal'
            WHEN max_cn = 1 THEN 'Heterozygous Deletion'
            WHEN max_cn = 0 THEN 'Homozygous Deletion'
        END AS subtype
    FROM case_band_cn
), 
summary AS (          -- counts of distinct cases per subtype & band
    SELECT
        "chromosome",
        "cytoband_name",
        COUNT(DISTINCT CASE WHEN subtype = 'Amplification'          THEN "case_barcode" END) AS ampl_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Gain'                   THEN "case_barcode" END) AS gain_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Homozygous Deletion'    THEN "case_barcode" END) AS homdel_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Heterozygous Deletion'  THEN "case_barcode" END) AS hetdel_cnt,
        COUNT(DISTINCT CASE WHEN subtype = 'Normal'                 THEN "case_barcode" END) AS normal_cnt
    FROM case_band_class
    GROUP BY
        "chromosome",
        "cytoband_name"
), 
total_cases AS (      -- total number of KIRC cases present
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM kirc_segs
)
SELECT
    s."chromosome",
    s."cytoband_name",
    ROUND(100.0 * ampl_cnt   / t.n_cases, 4) AS pct_amplification,
    ROUND(100.0 * gain_cnt    / t.n_cases, 4) AS pct_gain,
    ROUND(100.0 * homdel_cnt  / t.n_cases, 4) AS pct_homozygous_deletion,
    ROUND(100.0 * hetdel_cnt  / t.n_cases, 4) AS pct_heterozygous_deletion,
    ROUND(100.0 * normal_cnt  / t.n_cases, 4) AS pct_normal
FROM summary s
CROSS JOIN total_cases t
ORDER BY
    s."chromosome",
    s."cytoband_name";