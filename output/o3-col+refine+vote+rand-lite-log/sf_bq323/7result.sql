SELECT
    "seq_label",
    AVG("TR") AS "avg_TR",
    AVG("TE") AS "avg_TE",
    AVG("ST") AS "avg_ST",
    AVG("TR") + AVG("TE") + AVG("ST") AS "combined_overall_avg"
FROM (
    /*  T2-weighted axial sequences  */
    SELECT
        't2w_prostateX'                     AS "seq_label",
        "RepetitionTime"::FLOAT            AS "TR",
        "EchoTime"::FLOAT                  AS "TE",
        "SliceThickness"::FLOAT            AS "ST"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality"      = 'MR'
      AND LOWER("SeriesDescription") LIKE '%t2_tse_tra%'

    UNION ALL

    /*  ADC sequences  */
    SELECT
        'adc_prostateX'                    AS "seq_label",
        "RepetitionTime"::FLOAT            AS "TR",
        "EchoTime"::FLOAT                  AS "TE",
        "SliceThickness"::FLOAT            AS "ST"
    FROM IDC.IDC_V17.DICOM_ALL
    WHERE "collection_id" = 'prostatex'
      AND "Modality"      = 'MR'
      AND "SeriesDescription" ILIKE '%ADC%'
) AS sub
GROUP BY "seq_label";