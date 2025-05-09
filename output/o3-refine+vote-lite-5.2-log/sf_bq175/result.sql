WITH kirc_seg AS (          -- Kidney‑Renal Clear Cell Carcinoma segments, chr1 only
    SELECT
        s."case_barcode",
        s."chromosome",
        s."start_pos",
        s."end_pos",
        s."copy_number",
        s."major_copy_number",
        s."minor_copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome" = 'chr1'
),
bands AS (                  -- chr1 cytobands (hg38 coordinates)
    SELECT
        b."chromosome",
        b."hg38_start",
        b."hg38_stop",
        b."cytoband_name"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
    WHERE b."chromosome" = 'chr1'
),
seg_band AS (               -- overlap segments ↔ cytobands, classify CNV type
    SELECT
        b."cytoband_name",
        s."case_barcode",
        CASE
            WHEN s."copy_number" >= 4                                   THEN 'amp'      -- amplification
            WHEN s."copy_number"  = 3                                   THEN 'gain'     -- gain
            WHEN s."copy_number"  = 1 AND s."minor_copy_number" = 0     THEN 'het_del'  -- heterozygous deletion
        END AS "cnv_type"
    FROM kirc_seg  s
    JOIN bands     b
      ON s."start_pos" <= b."hg38_stop"
     AND s."end_pos"   >= b."hg38_start"
    WHERE ( (s."copy_number" >= 4)
         OR (s."copy_number"  = 3)
         OR (s."copy_number"  = 1 AND s."minor_copy_number" = 0) )
),
freq AS (                   -- frequency of each CNV type per cytoband
    SELECT
        "cytoband_name",
        "cnv_type",
        COUNT(*) AS freq
    FROM seg_band
    GROUP BY
        "cytoband_name",
        "cnv_type"
),
ranked AS (                 -- rank frequencies (highest = rank‑1)
    SELECT
        f.*,
        RANK() OVER (PARTITION BY "cnv_type"
                     ORDER BY freq DESC NULLS LAST) AS rnk
    FROM freq f
),
top11 AS (                  -- keep cytobands ranking within top‑11 for each CNV type
    SELECT
        "cytoband_name",
        "cnv_type"
    FROM ranked
    WHERE rnk <= 11
)
SELECT DISTINCT
    "cytoband_name"
FROM top11
GROUP BY
    "cytoband_name"
HAVING COUNT(DISTINCT "cnv_type") = 3          -- present in top‑11 of all three CNV classes
ORDER BY
    "cytoband_name";