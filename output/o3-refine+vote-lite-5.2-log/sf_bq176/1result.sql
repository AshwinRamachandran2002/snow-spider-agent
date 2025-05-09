WITH cytoband AS (   -- coordinates for 15q11 cytoband
    SELECT 
        REGEXP_REPLACE("chromosome", '^chr','')      AS "chr",
        "hg38_start"                                 AS "start_pos",
        "hg38_stop"                                  AS "end_pos"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "cytoband_name" LIKE '15q11%'              -- 15q11 and all sub‑bands
), seg_overlap AS (   -- copy‑number segments that overlap the cytoband
    SELECT
        seg."case_barcode",
        LEAST(seg."end_pos",  cyto."end_pos") 
        - GREATEST(seg."start_pos", cyto."start_pos") + 1  AS "ov_len",
        seg."segment_mean"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02 seg
    JOIN cytoband cyto
      ON seg."chromosome" = cyto."chr"
     AND seg."start_pos" <= cyto."end_pos"
     AND seg."end_pos"   >= cyto."start_pos"          -- overlap test
    WHERE seg."project_short_name" = 'TCGA-LAML'      -- LAML study only
)
SELECT
    "case_barcode",
    SUM("segment_mean" * "ov_len") / SUM("ov_len")    AS "weighted_avg_copy_number"
FROM seg_overlap
GROUP BY "case_barcode"
ORDER BY "weighted_avg_copy_number" DESC NULLS LAST;