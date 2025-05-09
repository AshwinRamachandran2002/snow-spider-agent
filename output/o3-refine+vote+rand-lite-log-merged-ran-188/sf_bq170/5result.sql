WITH brca_total AS (  -- total # of breast-cancer cases in Release-23
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-BRCA'
),

-- overlap-weighted, rounded copy number for every (case × cytoband)
band_cn AS (
    SELECT
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        s."case_barcode",
        ROUND(                                   -- weighted average CN, then round
            SUM(
                GREATEST(
                    0,
                    LEAST(c."hg38_stop", s."end_pos")
                  - GREATEST(c."hg38_start", s."start_pos")
                ) * s."copy_number"
            ) /
            NULLIF(
                SUM(
                    GREATEST(
                        0,
                        LEAST(c."hg38_stop", s."end_pos")
                      - GREATEST(c."hg38_start", s."start_pos")
                    )
                ),
                0
            )
        ) AS "rounded_cn"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                         c
    JOIN TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
      ON c."chromosome" = s."chromosome"
    WHERE s."project_short_name" = 'TCGA-BRCA'
      AND s."end_pos"   >= c."hg38_start"   -- segment overlaps cytoband
      AND s."start_pos" <= c."hg38_stop"
    GROUP BY
        c."cytoband_name",
        c."hg38_start",
        c."hg38_stop",
        s."case_barcode"
),

-- assign CNV category per (case × cytoband)
band_class AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        CASE
            WHEN "rounded_cn" = 0 THEN 'HomDel'
            WHEN "rounded_cn" = 1 THEN 'HetDel'
            WHEN "rounded_cn" = 2 THEN 'Diploid'
            WHEN "rounded_cn" = 3 THEN 'Gain'
            WHEN "rounded_cn" > 3 THEN 'Amplif'
        END AS "cnv_class"
    FROM band_cn
),

-- counts of each CNV class per cytoband
band_counts AS (
    SELECT
        "cytoband_name",
        "hg38_start",
        "hg38_stop",
        COUNT_IF("cnv_class" = 'HomDel')  AS "n_homdel",
        COUNT_IF("cnv_class" = 'HetDel')  AS "n_hetdel",
        COUNT_IF("cnv_class" = 'Diploid') AS "n_diploid",
        COUNT_IF("cnv_class" = 'Gain')    AS "n_gain",
        COUNT_IF("cnv_class" = 'Amplif')  AS "n_amplif"
    FROM band_class
    GROUP BY
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
)

-- final percentage frequencies
SELECT
    bc."cytoband_name",
    bc."hg38_start",
    bc."hg38_stop",
    ROUND(100.0 * bc."n_homdel" / bt."n_cases", 2) AS "pct_homdel",
    ROUND(100.0 * bc."n_hetdel" / bt."n_cases", 2) AS "pct_hetdel",
    ROUND(100.0 * bc."n_diploid" / bt."n_cases", 2) AS "pct_diploid",
    ROUND(100.0 * bc."n_gain"   / bt."n_cases", 2) AS "pct_gain",
    ROUND(100.0 * bc."n_amplif" / bt."n_cases", 2) AS "pct_amplif"
FROM band_counts bc
CROSS JOIN brca_total bt
ORDER BY bc."cytoband_name";