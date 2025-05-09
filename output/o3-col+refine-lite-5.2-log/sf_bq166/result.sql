/*  CNV‑frequency per cytoband for TCGA‑KIRC  */

WITH  total_cases AS (          -- denominator
       SELECT COUNT(DISTINCT "case_barcode")  AS "n_cases"
       FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
       WHERE  "project_short_name" = 'TCGA-KIRC' ),

/* 1. intersect every segment with every cytoband it overlaps               */
     seg_band AS (
       SELECT  s."case_barcode",
               s."copy_number",
               b."chromosome",
               b."cytoband_name"
       FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
       JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                       b
         ON  b."chromosome" = s."chromosome"
        AND  s."start_pos" < b."hg38_stop"
        AND  s."end_pos"   > b."hg38_start"
       WHERE  s."project_short_name" = 'TCGA-KIRC' ),

/* 2.  per case × cytoband take the maximal observed copy‑number             */
     max_cnv AS (
       SELECT  "case_barcode",
               "chromosome",
               "cytoband_name",
               MAX("copy_number") AS "max_cn"
       FROM    seg_band
       GROUP BY "case_barcode",
                "chromosome",
                "cytoband_name" ),

/* 3.  classify the maximum copy number                                      */
     classified AS (
       SELECT  m.*,
               CASE
                 WHEN "max_cn" > 3 THEN 'Amplification'
                 WHEN "max_cn" = 3 THEN 'Gain'
                 WHEN "max_cn" = 2 THEN 'Normal'
                 WHEN "max_cn" = 1 THEN 'Het_Del'
                 WHEN "max_cn" = 0 THEN 'Hom_Del'
               END AS "cnv_class"
       FROM   max_cnv  m )

/* 4.  frequency of each CNV class per cytoband                              */
SELECT  c."chromosome",
        c."cytoband_name",
        c."cnv_class",
        ROUND(100.0 * COUNT(DISTINCT c."case_barcode") / t."n_cases", 2) AS "frequency_percent"
FROM    classified   c
CROSS   JOIN total_cases  t
GROUP  BY c."chromosome",
          c."cytoband_name",
          c."cnv_class",
          t."n_cases"
ORDER BY c."chromosome",
         c."cytoband_name",
         c."cnv_class";