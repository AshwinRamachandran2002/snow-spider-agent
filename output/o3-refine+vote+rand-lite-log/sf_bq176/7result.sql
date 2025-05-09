/*  Weighted average copy‑number in cytoband 15q11 (chr15) – TCGA‑LAML  */
WITH band AS (       -- genomic span of cytoband 15q11
    SELECT
        "chromosome",
        "hg38_start"  AS band_start,
        "hg38_stop"   AS band_stop
    FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
    WHERE "chromosome" = 'chr15'
      AND "cytoband_name" ILIKE '15q11%'          -- include 15q11, 15q11.1, 15q11.2 …
), seg_overlap AS (   -- intersect copy‑number segments with the band interval(s)
    SELECT
        seg."case_barcode",
        /* length of the intersection between segment and band (0 when no overlap) */
        GREATEST(
            0,
            LEAST(seg."end_pos",   band.band_stop)
          - GREATEST(seg."start_pos", band.band_start) + 1
        )                                  AS overlap_len,
        seg."copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23 seg
    JOIN band
      ON seg."chromosome" = band."chromosome"
     AND seg."end_pos"   >= band.band_start      -- interval overlap test
     AND seg."start_pos" <= band.band_stop
    WHERE seg."project_short_name" = 'TCGA-LAML' -- only LAML study
      AND seg."copy_number" IS NOT NULL
), agg AS (          -- weighted average copy‑number per case
    SELECT
        "case_barcode",
        SUM(overlap_len * "copy_number")::FLOAT
        / NULLIF(SUM(overlap_len),0)      AS weighted_avg_copy_number
    FROM seg_overlap
    WHERE overlap_len > 0
    GROUP BY "case_barcode"
), max_val AS (      -- maximum weighted average across cases
    SELECT MAX(weighted_avg_copy_number) AS max_wacn
    FROM agg
)
SELECT
    a."case_barcode",
    a.weighted_avg_copy_number
FROM agg a
JOIN max_val m
  ON a.weighted_avg_copy_number = m.max_wacn   -- keep only top‑scoring case(s)
ORDER BY a."case_barcode";