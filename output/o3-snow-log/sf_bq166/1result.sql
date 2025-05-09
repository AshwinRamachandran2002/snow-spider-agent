/*  ----------------------------------------------------------------------------
    TCGA-KIRC : Cytoband-level CNV subtype frequencies (allelic segments)

    1)  Get the total number of distinct KIRC cases
    2)  For every case × cytoband, take the maximum copy-number observed
    3)  Convert that maximum to one of the five CNV sub-types
    4)  Count, per cytoband & subtype, how many distinct cases fall in it
    5)  Express the count as a percentage of the total KIRC case-count
    --------------------------------------------------------------------------- */
WITH total_cases AS (
    SELECT COUNT(DISTINCT "case_gdc_id") AS "total_cases"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
),

band_max AS (
    /* maximum copy-number that each case shows in every cytoband */
    SELECT
        seg."case_gdc_id",
        cb."chromosome",
        cb."cytoband_name",
        MAX(seg."copy_number") AS "max_cn_band"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 seg
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38 cb
         ON  cb."chromosome" = seg."chromosome"
         AND seg."start_pos" <= cb."hg38_stop"
         AND seg."end_pos"   >= cb."hg38_start"
    WHERE seg."project_short_name" = 'TCGA-KIRC'
    GROUP BY seg."case_gdc_id", cb."chromosome", cb."cytoband_name"
),

typed AS (
    /* translate the maximum copy-number into the requested CNV sub-type */
    SELECT
        "case_gdc_id",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_cn_band" > 3 THEN 'Amplification'
            WHEN "max_cn_band" = 3 THEN 'Gain'
            WHEN "max_cn_band" = 2 THEN 'Normal'
            WHEN "max_cn_band" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_cn_band" = 0 THEN 'Homozygous Deletion'
        END AS "cnv_subtype"
    FROM band_max
)

SELECT
    t."chromosome",
    t."cytoband_name",
    t."cnv_subtype",
    COUNT(DISTINCT t."case_gdc_id")                                     AS "n_cases",
    tc."total_cases",
    ROUND( (COUNT(DISTINCT t."case_gdc_id") * 100.0) / tc."total_cases", 4 ) AS "frequency_pct"
FROM typed t
CROSS JOIN total_cases tc
GROUP BY
    t."chromosome",
    t."cytoband_name",
    t."cnv_subtype",
    tc."total_cases"
ORDER BY
    t."chromosome",
    t."cytoband_name",
    t."cnv_subtype";