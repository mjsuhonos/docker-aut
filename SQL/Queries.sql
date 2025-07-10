# Top labels by frequency

WITH QIDFrequency AS (
    SELECT
        S.QID,
        COUNT(*) AS Frequency
    FROM
        Scores S
    GROUP BY
        S.QID
)
SELECT DISTINCT
    W.PrefLabel,
	S.QID,
    WP.Domain,
    QF.Frequency
FROM
    Scores S
JOIN
    Webpages WP ON S.Hash = WP.Hash
JOIN
    Wikidata W ON S.QID = W.QID
JOIN
    QIDFrequency QF ON S.QID = QF.QID
ORDER BY
    QF.Frequency DESC, -- Order by frequency of QID first
    S.Score DESC -- Then by score as a secondary order
LIMIT 50;

# OR group domains

SELECT 
    W.QID,
    W.PrefLabel,
    COUNT(S.QID) AS Frequency,
    GROUP_CONCAT(DISTINCT WP.Domain) AS AssociatedDomains
FROM 
    Scores S
JOIN 
    Wikidata W ON S.QID = W.QID
JOIN 
    Webpages WP ON S.Hash = WP.Hash
GROUP BY 
    W.QID, W.PrefLabel
ORDER BY 
    Frequency DESC
LIMIT 20;



# Top labels by domain

SELECT
    W.PrefLabel,
	WP.Domain,
    COUNT(*) AS LabelFrequency
FROM
    Wikidata W
JOIN
    Scores S ON W.QID = S.QID
JOIN
    Webpages WP ON S.Hash = WP.Hash
WHERE
    WP.Domain LIKE '%.com'
GROUP BY
    W.PrefLabel
ORDER BY
    LabelFrequency DESC
LIMIT 10;


# Top domains for a given QID

SELECT
    WP.Domain,
    COUNT(*) AS DomainFrequency
FROM
    Webpages WP
JOIN
    Scores S ON WP.Hash = S.Hash
WHERE
    S.QID = 'Q22686'
GROUP BY
    WP.Domain
ORDER BY
    DomainFrequency DESC;

# Top domains for a given label string

SELECT
    WP.Domain,
    COUNT(*) AS DomainFrequency
FROM
    Webpages WP
JOIN
    Scores S ON WP.Hash = S.Hash
JOIN
    Wikidata W ON S.QID = W.QID
WHERE
    W.PrefLabel LIKE 'Christ%'
GROUP BY
    WP.Domain
ORDER BY
    DomainFrequency DESC
LIMIT 10;




# Select similar domains for a given domain based on N labels

WITH TopLabels AS (
    SELECT
        W.PrefLabel
    FROM
        Wikidata W
    JOIN
        Scores S ON W.QID = S.QID
    JOIN
        Webpages WP ON S.Hash = WP.Hash
    WHERE
        WP.Domain = 'cbssports.com'
    GROUP BY
        W.PrefLabel
    ORDER BY
        COUNT(*) DESC
    LIMIT 5
),
DomainLabelFrequency AS (
    SELECT
        WP.Domain,
        W.PrefLabel,
        COUNT(*) AS Frequency
    FROM
        Webpages WP
    JOIN
        Scores S ON WP.Hash = S.Hash
    JOIN
        Wikidata W ON S.QID = W.QID
    WHERE
        W.PrefLabel IN (SELECT PrefLabel FROM TopLabels)
    GROUP BY
        WP.Domain, W.PrefLabel
),
SimilarDomains AS (
    SELECT
        DLF.Domain,
        SUM(DLF.Frequency) AS TotalFrequency
    FROM
        DomainLabelFrequency DLF
    JOIN
        TopLabels TL ON DLF.PrefLabel = TL.PrefLabel
    GROUP BY
        DLF.Domain
    HAVING
        DLF.Domain <> 'cbssports.com'
)
SELECT
    Domain,
    TotalFrequency
FROM
    SimilarDomains
ORDER BY
    TotalFrequency DESC
LIMIT 10;