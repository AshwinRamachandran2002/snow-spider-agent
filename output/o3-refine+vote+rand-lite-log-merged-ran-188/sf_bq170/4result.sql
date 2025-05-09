/*  Copy-number landscape for all cytobands in TCGA-BRCA (GDC Release-23, allelic segments)  */
WITH brca_segments AS (          -- 1.  BRCA allelic CNV segments
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

overlap_bp AS (                  -- 2.  Base-pair overlap between each segment and cytoband
    SELECT
        s."case_barcode",
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        /* overlap length in bp */
        GREATEST(
            0,
            LEAST(s."end_pos",  c."hg38_stop")  - 
            GREATEST(s."start_pos", c."hg38_start")
        )                               AS "ovlp",
        s."copy_number"
    FROM brca_segments  s
    JOIN TCGA_MITELMAN.PROD."CYTOBANDS_HG38" c
      ON c."chromosome" = s."chromosome"
    WHERE GREATEST(
              0,
              LEAST(s."end_pos",  c."hg38_stop")  - 
              GREATEST(s."start_pos", c."hg38_start")
          ) > 0                          -- keep only overlapping pieces
),

band_case_cn AS (               -- 3.  Overlap-weighted copy number per (case, cytoband)
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        ROUND(
            SUM("ovlp" * "copy_number") / NULLIF(SUM("ovlp"), 0)
        )                               AS "rounded_cn"
    FROM overlap_bp
    GROUP BY
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
),

band_case_type AS (             -- 4.  Map rounded CN to discrete CNV classes
    SELECT
        "case_barcode",
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "rounded_cn",
        CASE
            WHEN "rounded_cn" = 0 THEN 'Homozygous Deletion'
            WHEN "rounded_cn" = 1 THEN 'Heterozygous Deletion'
            WHEN "rounded_cn" = 2 THEN 'Diploid'
            WHEN "rounded_cn" = 3 THEN 'Gain'
            ELSE                       'Amplification'
        END                             AS "cnv_type"
    FROM band_case_cn
)

-- 5.  Frequency of each CNV category across all BRCA cases for every cytoband
SELECT
    "cytoband_name",
    "hg38_start",
    "hg38_stop",
    ROUND(100.0 * COUNT_IF("cnv_type" = 'Homozygous Deletion') / COUNT(*), 2)  AS "pct_homdel",
    ROUND(100.0 * COUNT_IF("cnv_type" = 'Heterozygous Deletion') / COUNT(*), 2)AS "pct_het_del",
    ROUND(100.0 * COUNT_IF("cnv_type" = 'Diploid')             / COUNT(*), 2)  AS "pct_diploid",
    ROUND(100.0 * COUNT_IF("cnv_type" = 'Gain')                / COUNT(*), 2)  AS "pct_gain",
    ROUND(100.0 * COUNT_IF("cnv_type" = 'Amplification')       / COUNT(*), 2)  AS "pct_amp"
FROM band_case_type
GROUP BY
    "cytoband_name",
    "hg38_start",
    "hg38_stop"
ORDER BY
    "cytoband_name";