WITH "kirc_segments" AS (   -- all KIRC segment-level CN calls
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
),

"cytobands" AS (            -- hg38 cytoband coordinates
    SELECT
        "chromosome",
        "cytoband_name",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
),

/*-----------------------------------------------------------
   1.  Overlap segments with cytobands & keep max CN / sample
-----------------------------------------------------------*/
"merged" AS (
    SELECT
        s."case_barcode",
        b."chromosome",
        b."cytoband_name",
        MAX(s."copy_number") AS "max_cn"
    FROM "kirc_segments" s
    JOIN "cytobands"   b
      ON s."chromosome" = b."chromosome"
     AND s."start_pos" <= b."hg38_stop"
     AND s."end_pos"   >= b."hg38_start"
    GROUP BY
        s."case_barcode",
        b."chromosome",
        b."cytoband_name"
),

/*-----------------------------------------------------------
   2.  Classify each sample-band into CN sub-types
-----------------------------------------------------------*/
"classified" AS (
    SELECT
        "case_barcode",
        "chromosome",
        "cytoband_name",
        "max_cn",
        CASE
            WHEN "max_cn" > 3 THEN 'Amplification'
            WHEN "max_cn" = 3 THEN 'Gain'
            WHEN "max_cn" = 0 THEN 'Homozygous Deletion'
            WHEN "max_cn" = 1 THEN 'Heterozygous Deletion'
            ELSE                 'Normal'
        END AS "cn_subtype"
    FROM "merged"
),

/*-----------------------------------------------------------
   3.  Count distinct cases in each band / subtype
-----------------------------------------------------------*/
"subtype_counts" AS (
    SELECT
        "chromosome",
        "cytoband_name",
        "cn_subtype",
        COUNT(DISTINCT "case_barcode") AS "num_cases"
    FROM "classified"
    GROUP BY
        "chromosome",
        "cytoband_name",
        "cn_subtype"
),

/*-----------------------------------------------------------
   4.  Total number of KIRC cases  (denominator for %)
-----------------------------------------------------------*/
"total_cases" AS (
    SELECT COUNT(DISTINCT "case_barcode") AS "total_cases"
    FROM "kirc_segments"
)

/*-----------------------------------------------------------
   5.  Final frequency table
-----------------------------------------------------------*/
SELECT
    sc."chromosome",
    sc."cytoband_name",
    sc."cn_subtype",
    sc."num_cases",
    ROUND(100.0 * sc."num_cases" / tc."total_cases", 2) AS "percentage_of_cases"
FROM "subtype_counts" sc
CROSS JOIN "total_cases" tc
ORDER BY
    sc."chromosome",
    sc."cytoband_name",
    sc."cn_subtype";