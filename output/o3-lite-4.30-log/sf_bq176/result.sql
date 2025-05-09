WITH band AS (
    SELECT "hg38_start",
           "hg38_stop"
    FROM   "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"
    WHERE  "cytoband_name" = '15q11'         -- exact cytoband
      AND  "chromosome"   = 'chr15'
), per_case AS (
    SELECT
        s."case_barcode",
        SUM( (LEAST(s."end_pos",  b."hg38_stop")
            - GREATEST(s."start_pos", b."hg38_start")) * s."segment_mean")     AS num,
        SUM(  LEAST(s."end_pos",  b."hg38_stop")
            - GREATEST(s."start_pos", b."hg38_start"))                        AS den
    FROM   "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
    JOIN   band b
           ON s."chromosome" = '15'                 -- segment is chr15 (already numeric in this table)
          AND s."start_pos" < b."hg38_stop"         -- overlap with band
          AND s."end_pos"   > b."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-LAML'
    GROUP BY s."case_barcode"
), weighted AS (
    SELECT
        "case_barcode",
        ROUND(num / den , 4) AS "weighted_avg_copy_number_15q11"
    FROM   per_case
)
SELECT  "case_barcode",
        "weighted_avg_copy_number_15q11"
FROM    (
        SELECT  *,
                RANK() OVER (ORDER BY "weighted_avg_copy_number_15q11" DESC) AS rnk
        FROM    weighted
) t
WHERE   rnk = 1;