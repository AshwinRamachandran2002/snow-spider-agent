/* 1) Pull the exact 15q11 cytoband span on chr15
   2) Intersect TCGA-LAML allelic CN segments with that span
   3) Compute the length-weighted average copy number per case
   4) Return the case barcode(s) whose average equals the cohort-wide maximum
*/
WITH cytoband_15q11 AS (   -- exact coordinates of 15q11-family
    SELECT  "chromosome",
            "hg38_start",
            "hg38_stop"
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE   "cytoband_name" ILIKE '15q11%'          -- catches 15q11, 15q11.1, 15q11.2 …
),

laml_weighted AS (        -- length-weighted average CN for every LAML case
    SELECT  s."case_barcode",
            SUM( (LEAST(s."end_pos",  c."hg38_stop")
                - GREATEST(s."start_pos", c."hg38_start") + 1) * s."copy_number"
               )                                           AS "weighted_cn_sum",
            SUM(  LEAST(s."end_pos",  c."hg38_stop")
                - GREATEST(s."start_pos", c."hg38_start") + 1
               )                                           AS "bp_overlap"
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  s
    JOIN    cytoband_15q11  c
           ON  s."chromosome" = c."chromosome"
          AND  s."start_pos" <= c."hg38_stop"
          AND  s."end_pos"   >= c."hg38_start"
    WHERE   s."project_short_name" = 'TCGA-LAML'
    GROUP BY s."case_barcode"
),

laml_avg AS (            -- convert sums to weighted average CN
    SELECT  "case_barcode",
            "weighted_cn_sum" / NULLIF("bp_overlap", 0) AS "weighted_avg_copy_number"
    FROM    laml_weighted
)

SELECT  "case_barcode",
        ROUND("weighted_avg_copy_number", 6) AS "weighted_avg_copy_number"
FROM    laml_avg
WHERE   "weighted_avg_copy_number" = (SELECT MAX("weighted_avg_copy_number")
                                      FROM   laml_avg)
ORDER BY "case_barcode";