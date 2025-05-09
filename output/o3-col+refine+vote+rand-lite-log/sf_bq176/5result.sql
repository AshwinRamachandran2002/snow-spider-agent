/*  Identify TCGA-LAML cases with the highest weighted-average copy number
    within cytoband 15q11 on chromosome 15 (hg38).
*/
WITH overlap AS (
    SELECT
        s."case_barcode",
        /* base-pairs of intersection between CN segment and cytoband */
        GREATEST(
            0,
            LEAST(s."end_pos",   c."hg38_stop")
          - GREATEST(s."start_pos", c."hg38_start") + 1
        )                                             AS "overlap_bp",
        /* absolute copy number:  CN = 2 * 2^(segment_mean) */
        2 * POWER(2, s."segment_mean")                AS "copy_number"
    FROM  TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02  s
    JOIN  TCGA_MITELMAN.PROD.CYTOBANDS_HG38                                             c
          ON c."chromosome" = 'chr' || s."chromosome"
    WHERE s."project_short_name" = 'TCGA-LAML'   -- study of interest
      AND s."chromosome"        = '15'           -- chromosome 15
      AND c."cytoband_name" ILIKE '15q11%'       -- cytoband 15q11 (and sub-bands)
      /* segment–cytoband overlap condition */
      AND s."start_pos" <= c."hg38_stop"
      AND s."end_pos"   >= c."hg38_start"
),
per_case AS (
    SELECT
        "case_barcode",
        SUM("overlap_bp" * "copy_number") / NULLIF(SUM("overlap_bp"),0)
            AS "weighted_avg_cn"
    FROM overlap
    GROUP BY "case_barcode"
),
max_cn AS (
    SELECT MAX("weighted_avg_cn") AS "max_cn"
    FROM   per_case
)
SELECT
    p."case_barcode",
    ROUND(p."weighted_avg_cn", 4) AS "weighted_avg_cn"
FROM   per_case  p
JOIN   max_cn    m  ON p."weighted_avg_cn" = m."max_cn"
ORDER  BY p."case_barcode";