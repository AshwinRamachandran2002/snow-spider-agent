/* --- highest weighted‑average copy number over cytoband 15q11 (chr15) in TCGA‑LAML --- */
WITH band AS (  /* genomic span of cytoband 15q11 on chr15 (hg38) */
    SELECT  MIN("hg38_start") AS start_pos ,
            MAX("hg38_stop")  AS end_pos
    FROM    TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE   "chromosome" = 'chr15'
      AND   "cytoband_name" ILIKE '15q11%'          -- e.g. 15q11, 15q11.1, 15q11.2
),

laml_cn AS (    /* length‑weighted sums for each TCGA‑LAML case */
    SELECT
        s."case_barcode",
        SUM( (LEAST(s."end_pos",   b.end_pos)
            - GREATEST(s."start_pos", b.start_pos) + 1) * s."copy_number" ) AS weighted_sum,
        SUM(  LEAST(s."end_pos",   b.end_pos)
            - GREATEST(s."start_pos", b.start_pos) + 1 )                    AS weight_total
    FROM    TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23  AS s
    CROSS   JOIN band AS b
    WHERE   s."project_short_name" = 'TCGA-LAML'      -- Acute Myeloid Leukemia
      AND   s."chromosome"        = 'chr15'
      AND   LEAST(s."end_pos", b.end_pos) > GREATEST(s."start_pos", b.start_pos)   -- overlaps 15q11
    GROUP BY s."case_barcode"
),

avg_cn AS (     /* weighted average copy number per case */
    SELECT
        "case_barcode",
        weighted_sum / weight_total AS weighted_cn
    FROM   laml_cn
)

SELECT
    "case_barcode",
    weighted_cn
FROM   avg_cn
WHERE  weighted_cn = (SELECT MAX(weighted_cn) FROM avg_cn)   -- retain highest value(s)
ORDER  BY "case_barcode";