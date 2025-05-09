WITH cytoband AS (      -- genomic coordinates for 15q11 (all sub-bands)
    SELECT
        "chromosome",
        "hg38_start",
        "hg38_stop"
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "cytoband_name" LIKE '15q11%'          -- 15q11, 15q11.1, 15q11.2 …
),
segments AS (           -- LAML allelic CN segments on chr15
    SELECT
        "case_barcode",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23
    WHERE "project_short_name" = 'TCGA-LAML'
      AND "chromosome" = 'chr15'
),
overlaps AS (           -- per-segment overlap with the cytoband
    SELECT
        s."case_barcode",
        GREATEST(s."start_pos", c."hg38_start") AS overlap_start,
        LEAST  (s."end_pos"  , c."hg38_stop" ) AS overlap_end,
        s."copy_number"
    FROM segments s
    JOIN cytoband c
      ON s."end_pos"   >= c."hg38_start"
     AND s."start_pos" <= c."hg38_stop"
),
weighted AS (           -- length-weighted copy-number statistics
    SELECT
        "case_barcode",
        SUM( (overlap_end - overlap_start + 1) * "copy_number" ) AS weighted_sum,
        SUM(  overlap_end - overlap_start + 1 )                  AS total_len
    FROM overlaps
    GROUP BY "case_barcode"
)
SELECT
    "case_barcode",
    weighted_sum / total_len AS weighted_avg_copy_number
FROM weighted
ORDER BY weighted_avg_copy_number DESC NULLS LAST;