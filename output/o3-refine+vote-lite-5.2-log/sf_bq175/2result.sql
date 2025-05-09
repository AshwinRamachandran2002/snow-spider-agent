WITH "segments" AS (   -- chr1 CNV segments from TCGA‑KIRC
    SELECT
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
      AND "chromosome"        = 'chr1'
),
"bands" AS (           -- chr1 cytobands (hg38)
    SELECT
        "chromosome",
        "hg38_start"  AS "band_start",
        "hg38_stop"   AS "band_stop",
        "cytoband_name"
    FROM TCGA_MITELMAN.PROD."CYTOBANDS_HG38"
    WHERE "chromosome" = 'chr1'
),
"overlaps" AS (        -- segment ↔ band overlaps + CNV category
    SELECT
        b."cytoband_name",
        CASE
            WHEN s."copy_number" > 3 THEN 'Amplification'
            WHEN s."copy_number" = 3 THEN 'Gain'
            WHEN s."copy_number" = 1 THEN 'HeterozygousDeletion'
        END AS "category"
    FROM "segments" s
    JOIN "bands"    b
         ON  s."start_pos" <= b."band_stop"
         AND s."end_pos"   >= b."band_start"
    WHERE s."copy_number" IN (1,3) OR s."copy_number" > 3      -- only relevant classes
),
"freqs" AS (           -- frequency per band & category
    SELECT
        "cytoband_name",
        "category",
        COUNT(*) AS "freq"
    FROM "overlaps"
    GROUP BY "cytoband_name", "category"
),
"ranks" AS (           -- rank of each band inside every category
    SELECT
        "cytoband_name",
        "category",
        "freq",
        RANK() OVER (PARTITION BY "category"
                     ORDER BY "freq" DESC NULLS LAST) AS "rnk"
    FROM "freqs"
),
"pivoted" AS (         -- put the three ranks on the same row
    SELECT
        "cytoband_name",
        MAX(CASE WHEN "category" = 'Amplification'        THEN "rnk" END) AS "amplification_rank",
        MAX(CASE WHEN "category" = 'Gain'                 THEN "rnk" END) AS "gain_rank",
        MAX(CASE WHEN "category" = 'HeterozygousDeletion' THEN "rnk" END) AS "hetdel_rank"
    FROM "ranks"
    GROUP BY "cytoband_name"
)
SELECT
    "cytoband_name",
    "amplification_rank",
    "gain_rank",
    "hetdel_rank"
FROM "pivoted"
WHERE "amplification_rank"  <= 11
  AND "gain_rank"           <= 11
  AND "hetdel_rank"         <= 11
ORDER BY
    "amplification_rank",
    "gain_rank",
    "hetdel_rank",
    "cytoband_name";