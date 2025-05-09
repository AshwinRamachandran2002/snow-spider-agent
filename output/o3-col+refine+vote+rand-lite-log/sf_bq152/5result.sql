/* ---------------------------------------------------------------
   Copy-number state distribution for TCGA-BRCA (per chromosome)
-----------------------------------------------------------------*/
WITH chr_limits AS (   -- span covered per chromosome
    SELECT  "chromosome",
            MIN("start_pos") AS "chr_start",
            MAX("end_pos")   AS "chr_end"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
    GROUP BY "chromosome"
), brca_cases AS (      -- unique BRCA cases
    SELECT DISTINCT "case_barcode"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED"
    WHERE "project_short_name" = 'TCGA-BRCA'
), overlaps AS (        -- intersect segments with whole-chromosome windows
    SELECT
        l."chromosome",
        l."chr_start",
        l."chr_end",
        s."case_barcode",
        LEAST(s."end_pos", l."chr_end")
          - GREATEST(s."start_pos", l."chr_start")     AS "ovl_len",
        s."segment_mean"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."COPY_NUMBER_SEGMENT_MASKED" s
    JOIN chr_limits l
      ON s."chromosome" = l."chromosome"
     AND s."project_short_name" = 'TCGA-BRCA'
     AND s."start_pos" < l."chr_end"
     AND s."end_pos"   > l."chr_start"
), cn_per_case_chr AS ( -- overlap-weighted CN, then rounded
    SELECT
        "chromosome",
        "chr_start",
        "chr_end",
        "case_barcode",
        ROUND(
            SUM("ovl_len" * 2 * POWER(2, "segment_mean"))
            / NULLIF(SUM("ovl_len"),0)
        ) AS "rounded_cn"
    FROM overlaps
    GROUP BY "chromosome","chr_start","chr_end","case_barcode"
), typed AS (           -- assign CNV class
    SELECT
        "chromosome",
        "chr_start",
        "chr_end",
        "case_barcode",
        CASE
            WHEN "rounded_cn" = 0 THEN 'HOMO_DELETION'
            WHEN "rounded_cn" = 1 THEN 'HET_DELETION'
            WHEN "rounded_cn" = 2 THEN 'NORMAL'
            WHEN "rounded_cn" = 3 THEN 'GAIN'
            WHEN "rounded_cn" > 3 THEN 'AMPLIFICATION'
            ELSE 'UNKNOWN'
        END AS "cnv_type"
    FROM cn_per_case_chr
), totals AS ( SELECT COUNT(*) AS "n_cases" FROM brca_cases )

SELECT
    t."chromosome",
    t."chr_start"                      AS "start_pos",
    t."chr_end"                        AS "end_pos",
    ROUND(100 * COUNT_IF(t."cnv_type" = 'HOMO_DELETION') / totals."n_cases", 2)  AS "pct_homo_del",
    ROUND(100 * COUNT_IF(t."cnv_type" = 'HET_DELETION')  / totals."n_cases", 2)  AS "pct_het_del",
    ROUND(100 * COUNT_IF(t."cnv_type" = 'NORMAL')        / totals."n_cases", 2)  AS "pct_normal",
    ROUND(100 * COUNT_IF(t."cnv_type" = 'GAIN')          / totals."n_cases", 2)  AS "pct_gain",
    ROUND(100 * COUNT_IF(t."cnv_type" = 'AMPLIFICATION') / totals."n_cases", 2)  AS "pct_amplification"
FROM typed t
CROSS JOIN totals
GROUP BY
    t."chromosome",
    t."chr_start",
    t."chr_end",
    totals."n_cases"
ORDER BY
    CASE
        WHEN t."chromosome" = 'X' THEN 23
        WHEN t."chromosome" = 'Y' THEN 24
        ELSE TO_NUMBER(t."chromosome")
    END,
    t."chr_start";