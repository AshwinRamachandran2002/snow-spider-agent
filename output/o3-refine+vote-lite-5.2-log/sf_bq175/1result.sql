/*  ---------------------------------------------------------------
    Cytobands on chromosome 1 whose  kidney‑cancer (TCGA‑KIRC)
    copy‑number segments are simultaneously among the 11 most‑
    frequent for:  amplifications (CN ≥ 4), gains (CN = 3), and
    heterozygous deletions (CN = 1 & minor CN = 0)
    --------------------------------------------------------------- */
WITH kirc_seg AS (          -- kidney‑cancer allelic segments
    SELECT  "case_barcode",
            "chromosome",
            "start_pos",
            "end_pos",
            "copy_number",
            "major_copy_number",
            "minor_copy_number"
    FROM    TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE   "project_short_name" = 'TCGA-KIRC'
      AND   "chromosome" IN ('chr1','1')
), overlap AS (             -- segments ↔ cytobands overlap & category
    SELECT  DISTINCT
            b."cytoband_name",
            s."case_barcode",
            CASE
                WHEN s."copy_number" >= 4                                     THEN 'Amplification'
                WHEN s."copy_number"  = 3                                     THEN 'Gain'
                WHEN s."copy_number"  = 1 AND s."minor_copy_number" = 0       THEN 'Heterozygous Deletion'
            END                                                         AS "category"
    FROM        kirc_seg            s
    JOIN        TCGA_MITELMAN.PROD."CYTOBANDS_HG38"  b
           ON   b."chromosome" = 'chr1'
          AND   s."start_pos"  <= b."hg38_stop"
          AND   s."end_pos"    >= b."hg38_start"
    WHERE (s."copy_number" >= 4)
       OR (s."copy_number"  = 3)
       OR (s."copy_number"  = 1 AND s."minor_copy_number" = 0)
), freq_per_band AS (       -- how many distinct cases per band & category
    SELECT  "cytoband_name",
            "category",
            COUNT(DISTINCT "case_barcode") AS "freq"
    FROM    overlap
    GROUP BY 1,2
), ranked AS (              -- rank frequencies within each category
    SELECT  "cytoband_name",
            "category",
            "freq",
            DENSE_RANK() OVER (PARTITION BY "category"
                               ORDER BY "freq" DESC NULLS LAST) AS "rk"
    FROM    freq_per_band
)
SELECT  DISTINCT "cytoband_name"
FROM    ranked
GROUP BY "cytoband_name"
HAVING  MAX(CASE WHEN "category" = 'Amplification'         THEN "rk" END) <= 11
    AND MAX(CASE WHEN "category" = 'Gain'                  THEN "rk" END) <= 11
    AND MAX(CASE WHEN "category" = 'Heterozygous Deletion' THEN "rk" END) <= 11
ORDER BY "cytoband_name";