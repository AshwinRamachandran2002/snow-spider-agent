WITH cytoband_15q11 AS (
    /* get genomic span of cytoband 15q11 (all 15q11 sub‑bands) in hg38 coordinates */
    SELECT  MIN("hg38_start") AS band_start ,
            MAX("hg38_stop")  AS band_end
    FROM    TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
    WHERE   "chromosome"      = 'chr15'
      AND   "cytoband_name"  ILIKE '15q11%'
),
segments_in_band AS (
    /* pick copy‑number segments from TCGA‑LAML that overlap the band */
    SELECT  seg."case_barcode",
            seg."segment_mean"                           AS copy_val,
            GREATEST(seg."start_pos", cb.band_start)     AS ov_start,
            LEAST (seg."end_pos" , cb.band_end )         AS ov_end
    FROM    TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" seg ,
            cytoband_15q11                               cb
    WHERE   seg."project_short_name" = 'TCGA-LAML'
      AND   seg."chromosome"         = '15'
      AND   seg."segment_mean"       IS NOT NULL
      AND   seg."end_pos"            >= cb.band_start      -- overlap test
      AND   seg."start_pos"          <= cb.band_end
),
weighted_avg AS (
    /* length‑weighted average copy number per case */
    SELECT  "case_barcode",
            SUM(copy_val * (ov_end - ov_start + 1)) / 
            SUM(       (ov_end - ov_start + 1))      AS weighted_avg_copy
    FROM    segments_in_band
    GROUP BY "case_barcode"
),
ranked AS (
    SELECT  *,
            RANK() OVER (ORDER BY weighted_avg_copy DESC) AS rnk
    FROM    weighted_avg
)
SELECT  "case_barcode",
        weighted_avg_copy
FROM    ranked
WHERE   rnk = 1          -- highest weighted average copy number
ORDER BY "case_barcode";