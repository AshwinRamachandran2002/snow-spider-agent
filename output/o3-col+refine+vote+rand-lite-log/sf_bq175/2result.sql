/*  Cytobands on chromosome-1 in TCGA-KIRC whose amplification (CN ≥ 4),
    gain (CN = 3) and heterozygous-deletion (CN = 1) frequencies all
    rank within the top 11 (masked-segment dataset, CN derived from
    segment_mean)                                                  */

WITH kirc_seg AS (                           -- TCGA-KIRC CN segments on chr1
    SELECT
        'chr1'                                                AS "chromosome",
        s."start_pos",
        s."end_pos",
        /* convert segment_mean (log2(CN/2)) to absolute CN and round */
        ROUND( 2 * POWER(2, s."segment_mean") ) :: INTEGER   AS "copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_MASKED_HG38_GDC_2017_02" s
    WHERE s."project_short_name" = 'TCGA-KIRC'
      AND s."chromosome"         = '1'
),                          
seg_to_band AS (                          -- map segments to cytobands (hg38)
    SELECT
        b."cytoband_name",
        k."copy_number"
    FROM kirc_seg k
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38" b
      ON b."chromosome" = 'chr1'
     AND k."start_pos"  <= b."hg38_stop"
     AND k."end_pos"    >= b."hg38_start"
),                          
amp AS (                                   -- amplification ranks (CN ≥ 4)
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY COUNT(*) DESC) AS "amp_rank"
    FROM seg_to_band
    WHERE "copy_number" >= 4
    GROUP BY "cytoband_name"
),                         
gain AS (                                  -- gain ranks (CN = 3)
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY COUNT(*) DESC) AS "gain_rank"
    FROM seg_to_band
    WHERE "copy_number" = 3
    GROUP BY "cytoband_name"
),                          
hetdel AS (                                -- heterozygous-deletion ranks (CN = 1)
    SELECT
        "cytoband_name",
        RANK() OVER (ORDER BY COUNT(*) DESC) AS "hetdel_rank"
    FROM seg_to_band
    WHERE "copy_number" = 1
    GROUP BY "cytoband_name"
)
SELECT
    a."cytoband_name",
    a."amp_rank",
    g."gain_rank",
    h."hetdel_rank"
FROM amp   a
JOIN gain  g ON a."cytoband_name" = g."cytoband_name"
JOIN hetdel h ON a."cytoband_name" = h."cytoband_name"
WHERE a."amp_rank"  <= 11
  AND g."gain_rank" <= 11
  AND h."hetdel_rank" <= 11
ORDER BY a."amp_rank" NULLS LAST,
         a."cytoband_name";