/*  Cytobands on chromosome 1 that simultaneously fall
    within the TOP‑11 for amplifications (≥4 copies),
    gains (=3 copies), and heterozygous deletions (1/0 copies)
    in the TCGA‑KIRC allelic‑segment data.                 */

WITH
/* ---------- per‑event frequency & ranking --------------- */
amp AS (
    SELECT  b."cytoband_name",
            RANK() OVER (ORDER BY COUNT(DISTINCT s."case_barcode") DESC) AS rk
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
           ON  b."chromosome" = s."chromosome"
          AND s."start_pos"  <= b."hg38_stop"
          AND s."end_pos"    >= b."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
      AND  s."chromosome"        = 'chr1'
      AND  s."copy_number"       >= 4              -- amplification
    GROUP  BY b."cytoband_name"
    QUALIFY rk <= 11
),
gain AS (
    SELECT  b."cytoband_name",
            RANK() OVER (ORDER BY COUNT(DISTINCT s."case_barcode") DESC) AS rk
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
           ON  b."chromosome" = s."chromosome"
          AND s."start_pos"  <= b."hg38_stop"
          AND s."end_pos"    >= b."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
      AND  s."chromosome"        = 'chr1'
      AND  s."copy_number"        = 3              -- gain
    GROUP  BY b."cytoband_name"
    QUALIFY rk <= 11
),
hetdel AS (
    SELECT  b."cytoband_name",
            RANK() OVER (ORDER BY COUNT(DISTINCT s."case_barcode") DESC) AS rk
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23" s
    JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38" b
           ON  b."chromosome" = s."chromosome"
          AND s."start_pos"  <= b."hg38_stop"
          AND s."end_pos"    >= b."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
      AND  s."chromosome"        = 'chr1'
      AND  s."copy_number"        = 1              -- heterozygous deletion
      AND  s."major_copy_number"  = 1
      AND  s."minor_copy_number"  = 0
    GROUP  BY b."cytoband_name"
    QUALIFY rk <= 11
),
/* ---------- intersection of the three TOP‑11 lists ------- */
common AS (
    SELECT  a."cytoband_name"
    FROM    amp a
    INNER JOIN gain   g ON g."cytoband_name" = a."cytoband_name"
    INNER JOIN hetdel h ON h."cytoband_name" = a."cytoband_name"
)
/* ---------- final output --------------------------------- */
SELECT 'amplification'        AS event_type,
       a."cytoband_name",
       a.rk                   AS rank
FROM   amp a
JOIN   common c USING ("cytoband_name")

UNION ALL
SELECT 'gain',
       g."cytoband_name",
       g.rk
FROM   gain g
JOIN   common c USING ("cytoband_name")

UNION ALL
SELECT 'heterozygous_deletion',
       h."cytoband_name",
       h.rk
FROM   hetdel h
JOIN   common c USING ("cytoband_name")

ORDER BY event_type, rank, "cytoband_name";