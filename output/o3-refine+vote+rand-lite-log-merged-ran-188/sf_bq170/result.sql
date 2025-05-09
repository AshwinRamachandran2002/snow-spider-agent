/*  CNV–class frequencies for every cytoband across all TCGA-BRCA cases (GDC R23, allelic segments)  */
WITH brca_cases AS (        -- all BRCA cases present in the Release-23 allelic segment table
    SELECT DISTINCT "case_barcode"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

/*  compute base-pair overlap between each BRCA CN-segment and every cytoband
    on the same chromosome                                                  */
overlap_segments AS (
    SELECT
        cb."cytoband_name",
        cb."hg38_start",
        cb."hg38_stop",
        seg."case_barcode",
        GREATEST(
            0,
            LEAST(cb."hg38_stop", seg."end_pos")
            - GREATEST(cb."hg38_start", seg."start_pos")
        )                           AS "overlap_len",
        seg."copy_number"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38" cb
    JOIN TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" seg
      ON seg."chromosome" = cb."chromosome"
    WHERE seg."project_short_name" = 'TCGA-BRCA'
),

/*  overlap-weighted average CN per (case, cytoband)                        */
weighted_cn_per_case AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        "case_barcode",
        ROUND(
            SUM("overlap_len" * "copy_number")
            / NULLIF(SUM("overlap_len"), 0)
        )                      AS "rounded_cn"
    FROM overlap_segments
    WHERE "overlap_len" > 0
    GROUP BY "cytoband_name", "hg38_start", "hg38_stop", "case_barcode"
),

/*  translate rounded CN to CNV classes                                     */
classified AS (
    SELECT
        wc."cytoband_name",
        wc."hg38_start",
        wc."hg38_stop",
        CASE
            WHEN wc."rounded_cn" = 0 THEN 'homozygous_deletion'
            WHEN wc."rounded_cn" = 1 THEN 'heterozygous_deletion'
            WHEN wc."rounded_cn" = 2 THEN 'diploid'
            WHEN wc."rounded_cn" = 3 THEN 'gain'
            WHEN wc."rounded_cn" > 3 THEN 'amplification'
        END                AS "cnv_class"
    FROM weighted_cn_per_case wc
)

/*  percentage of BRCA cases in each CNV class for every cytoband           */
SELECT
    c."cytoband_name",
    c."hg38_start",
    c."hg38_stop",
    ROUND(
        100.0 * SUM(IFF(c."cnv_class" = 'homozygous_deletion', 1, 0))
        / (SELECT COUNT(*) FROM brca_cases), 2
    ) AS "pct_homozygous_deletion",
    ROUND(
        100.0 * SUM(IFF(c."cnv_class" = 'heterozygous_deletion', 1, 0))
        / (SELECT COUNT(*) FROM brca_cases), 2
    ) AS "pct_heterozygous_deletion",
    ROUND(
        100.0 * SUM(IFF(c."cnv_class" = 'diploid', 1, 0))
        / (SELECT COUNT(*) FROM brca_cases), 2
    ) AS "pct_diploid",
    ROUND(
        100.0 * SUM(IFF(c."cnv_class" = 'gain', 1, 0))
        / (SELECT COUNT(*) FROM brca_cases), 2
    ) AS "pct_gain",
    ROUND(
        100.0 * SUM(IFF(c."cnv_class" = 'amplification', 1, 0))
        / (SELECT COUNT(*) FROM brca_cases), 2
    ) AS "pct_amplification"
FROM classified c
GROUP BY c."cytoband_name", c."hg38_start", c."hg38_stop"
ORDER BY c."cytoband_name";