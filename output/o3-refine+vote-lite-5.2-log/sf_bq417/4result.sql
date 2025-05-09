SELECT
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesNumber",
    "SeriesDescription",
    "BodyPartExamined",
    "series_aws_url"                                         AS "SeriesAWSURL",
    ROUND(SUM("instance_size") / 1000000.0, 2)               AS "SeriesSizeMB"
FROM
    IDC.IDC_V17.DICOM_ALL
WHERE
    "PatientSex" = 'M'
    AND TO_NUMBER(REGEXP_SUBSTR("PatientAge", '[0-9]+')) = 18
    AND UPPER("BodyPartExamined") = 'MEDIASTINUM'
    AND "StudyDate" > '2014-09-01'
GROUP BY
    "PatientID",
    "PatientSex",
    "PatientAge",
    "StudyInstanceUID",
    "StudyDate",
    "SeriesInstanceUID",
    "SeriesNumber",
    "SeriesDescription",
    "BodyPartExamined",
    "series_aws_url"
ORDER BY
    "PatientID",
    "SeriesInstanceUID";