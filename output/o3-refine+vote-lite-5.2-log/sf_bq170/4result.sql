/* -------------------------------------------------------------
   Copy‑number landscape (CNV) per cytoband for TCGA‑BRCA cases
   GDC archive – Release 23  (allelic masked segments, hg38)
----------------------------------------------------------------*/
WITH
/* 1. All BRCA copy‑number segments (Release 23) -----------------*/
segments AS (
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),
/* 2. Total distinct BRCA cases ----------------------------------*/
total_cases AS (
    SELECT COUNT(DISTINCT "case_barcode") AS total_n
    FROM segments
),
/* 3. hg38 cytoband coordinates ---------------------------------*/
cytobands AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),
/* 4. Base‑pair overlap between segments and cytobands -----------*/
band_seg AS (
    SELECT
        cb."chromosome",
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        s."case_barcode",
        LEAST(s."end_pos", cb."hg38_stop")
          - GREATEST(s."start_pos", cb."hg38_start")          AS overlap_bp,
        s."copy_number"
    FROM segments s
    JOIN cytobands cb
      ON cb."chromosome" = s."chromosome"
     AND s."end_pos"   > cb."hg38_start"
     AND s."start_pos" < cb."hg38_stop"
    WHERE LEAST(s."end_pos", cb."hg38_stop")
        - GREATEST(s."start_pos", cb."hg38_start") > 0
),
/* 5. Weighted average copy‑number per (case × cytoband) ---------*/
band_case AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND(
            SUM(overlap_bp * "copy_number")::FLOAT
            / NULLIF(SUM(overlap_bp),0)
        ) AS rounded_cn
    FROM band_seg
    GROUP BY
        "chromosome","cytoband_name","hg38_start",
        "hg38_stop","case_barcode"
),
/* 6. CNV category assignment ------------------------------------*/
band_case_cnv AS (
    SELECT
        *,
        CASE
            WHEN rounded_cn = 0 THEN 'Homozygous Deletion'
            WHEN rounded_cn = 1 THEN 'Heterozygous Deletion'
            WHEN rounded_cn = 2 THEN 'Diploid'
            WHEN rounded_cn = 3 THEN 'Gain'
            WHEN rounded_cn >  3 THEN 'Amplification'
            ELSE               'Unclassified'
        END AS cnv_type
    FROM band_case
)
/* 7. Cytoband‑level frequency table -----------------------------*/
SELECT
    b."chromosome",
    b."cytoband_name",
    b."hg38_start",
    b."hg38_stop",

    /* frequency (%) of each CNV type, two decimals */
    ROUND(100.0 * SUM(IFF(b.cnv_type = 'Homozygous Deletion',1,0))
                / MAX(tc.total_n), 2) AS pct_homo_del,

    ROUND(100.0 * SUM(IFF(b.cnv_type = 'Heterozygous Deletion',1,0))
                / MAX(tc.total_n), 2) AS pct_hetero_del,

    ROUND(100.0 * SUM(IFF(b.cnv_type = 'Diploid',1,0))
                / MAX(tc.total_n), 2) AS pct_diploid,

    ROUND(100.0 * SUM(IFF(b.cnv_type = 'Gain',1,0))
                / MAX(tc.total_n), 2) AS pct_gain,

    ROUND(100.0 * SUM(IFF(b.cnv_type = 'Amplification',1,0))
                / MAX(tc.total_n), 2) AS pct_amplification
FROM band_case_cnv b
CROSS JOIN total_cases tc
GROUP BY
    b."chromosome",
    b."cytoband_name",
    b."hg38_start",
    b."hg38_stop"
ORDER BY
    b."chromosome",
    b."hg38_start";