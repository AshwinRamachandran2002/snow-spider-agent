/* -- TCGA-LAML case(s) with the highest length-weighted average
      absolute copy number inside cytoband 15q11 on chromosome 15 */

WITH q11_band AS (               -- genomic span(s) of 15q11 in hg38
  SELECT
      "hg38_start" AS band_start,
      "hg38_stop"  AS band_stop
  FROM TCGA_MITELMAN.PROD.CYTOBANDS_HG38
  WHERE "chromosome" = 'chr15'
    AND "cytoband_name" ILIKE '15q11%'          -- 15q11, 15q11.1, 15q11.2, …
),

overlaps AS (                    -- segments that overlap the band
  SELECT
      s."case_barcode",
      /* length of the intersection with the band */
      LEAST(s."end_pos", b.band_stop)
      - GREATEST(s."start_pos", b.band_start) + 1          AS ov_len,
      /* absolute copy number for the segment */
      2 * POWER(2, s."segment_mean")                       AS abs_cn
  FROM TCGA_MITELMAN.TCGA_VERSIONED.COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_R14 s
  JOIN q11_band b
        ON s."start_pos" <= b.band_stop
       AND s."end_pos"   >= b.band_start
  WHERE s."project_short_name" = 'TCGA-LAML'
    AND s."chromosome" = '15'
    AND s."segment_mean" IS NOT NULL
),

per_case AS (                    -- length-weighted mean absolute CN
  SELECT
      "case_barcode",
      SUM(ov_len * abs_cn) / SUM(ov_len)  AS weighted_avg_copy_number
  FROM overlaps
  GROUP BY "case_barcode"
)

SELECT
    "case_barcode",
    ROUND(weighted_avg_copy_number, 6) AS "weighted_avg_copy_number"
FROM per_case
QUALIFY RANK() OVER (ORDER BY weighted_avg_copy_number DESC) = 1   -- keep highest
ORDER BY "case_barcode";