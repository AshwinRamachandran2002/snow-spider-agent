/* -----------------------------------------------------------------------
   Description:  For TCGA-KIRC samples, determine the maximum copy number
   per cytoband for every case, classify the value into five CNV sub-types,
   and report the percentage of cases that fall into each subtype for every
   cytoband.  Percentages are calculated with respect to the total number
   of distinct TCGA-KIRC cases and are ordered by chromosome and cytoband.
------------------------------------------------------------------------ */
WITH total_cases AS (   -- total distinct KIRC cases (denominator)
    SELECT COUNT(DISTINCT "case_barcode") AS "n_cases"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-KIRC'
),

joined AS (              -- overlap CN segments with cytobands
    SELECT
        s."case_barcode",
        c."cytoband_name",
        c."chromosome",
        s."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  s
    JOIN TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                     c
      ON s."chromosome" = c."chromosome"
     AND LEAST(s."end_pos",   c."hg38_stop")  > 
         GREATEST(s."start_pos", c."hg38_start")          -- ensure overlap
    WHERE s."project_short_name" = 'TCGA-KIRC'
),

max_cn AS (               -- maximum CN observed per case × cytoband
    SELECT
        "case_barcode",
        "cytoband_name",
        "chromosome",
        MAX("copy_number") AS "max_copy_number"
    FROM joined
    GROUP BY "case_barcode", "cytoband_name", "chromosome"
),

classified AS (           -- translate max CN to CNV class labels
    SELECT
        "case_barcode",
        "cytoband_name",
        "chromosome",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
            WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
        END AS "cnv_class"
    FROM max_cn
)

SELECT
    "chromosome",
    "cytoband_name",
    "cnv_class",
    ROUND( 100.0 * COUNT(DISTINCT "case_barcode") 
           / (SELECT "n_cases" FROM total_cases), 2 ) AS "percentage_cases"
FROM classified
GROUP BY "chromosome", "cytoband_name", "cnv_class"
ORDER BY "chromosome", "cytoband_name", "cnv_class";