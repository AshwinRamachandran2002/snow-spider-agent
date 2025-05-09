WITH brca_segments AS (   -- copy‑number segments for TCGA‑BRCA cases (GDC R23, hg38)
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

cytobands AS (            -- hg38 cytoband coordinates
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
),

band_segment_overlap AS ( -- overlap of each segment with each cytoband
    SELECT
        s."case_barcode",
        b."cytoband_name",
        b."hg38_start",
        b."hg38_stop",
        GREATEST(
            0,
            LEAST(b."hg38_stop",  s."end_pos")
          - GREATEST(b."hg38_start",s."start_pos") + 1
        )                           AS overlap_len,
        s."copy_number"             AS seg_cn
    FROM brca_segments s
    JOIN cytobands b
      ON s."chromosome" = b."chromosome"
     AND s."end_pos"   >= b."hg38_start"
     AND s."start_pos" <= b."hg38_stop"
),

band_cn AS (              -- weighted average copy number per cytoband/case
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        SUM(overlap_len * seg_cn) / NULLIF(SUM(overlap_len),0) AS weighted_cn
    FROM band_segment_overlap
    WHERE overlap_len > 0
    GROUP BY "case_barcode","cytoband_name","hg38_start","hg38_stop"
),

band_cnv AS (             -- round & classify
    SELECT
        *,
        ROUND(weighted_cn) AS rounded_cn,
        CASE ROUND(weighted_cn)
             WHEN 0 THEN 'Homozygous Deletion'
             WHEN 1 THEN 'Heterozygous Deletion'
             WHEN 2 THEN 'Diploid'
             WHEN 3 THEN 'Gain'
             ELSE      'Amplification'
        END AS cnv_type
    FROM band_cn
),

total_cases AS (          -- total BRCA cases
    SELECT COUNT(DISTINCT "case_barcode") AS n_cases
    FROM brca_segments
)

-- frequency of each CNV type per cytoband
SELECT
    bc."cytoband_name",
    bc."hg38_start",
    bc."hg38_stop",
    ROUND(100 * SUM(CASE WHEN cnv_type = 'Homozygous Deletion'   THEN 1 ELSE 0 END) / MAX(t.n_cases), 2) AS "pct_homozygous_deletion",
    ROUND(100 * SUM(CASE WHEN cnv_type = 'Heterozygous Deletion' THEN 1 ELSE 0 END) / MAX(t.n_cases), 2) AS "pct_heterozygous_deletion",
    ROUND(100 * SUM(CASE WHEN cnv_type = 'Diploid'               THEN 1 ELSE 0 END) / MAX(t.n_cases), 2) AS "pct_diploid",
    ROUND(100 * SUM(CASE WHEN cnv_type = 'Gain'                  THEN 1 ELSE 0 END) / MAX(t.n_cases), 2) AS "pct_gain",
    ROUND(100 * SUM(CASE WHEN cnv_type = 'Amplification'         THEN 1 ELSE 0 END) / MAX(t.n_cases), 2) AS "pct_amplification"
FROM band_cnv bc
CROSS JOIN total_cases t
GROUP BY bc."cytoband_name", bc."hg38_start", bc."hg38_stop"
ORDER BY bc."cytoband_name";