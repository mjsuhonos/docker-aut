# Top domains by label frequency

SELECT w.Domain, COUNT(s.QID) as LabelFrequency,
    GROUP_CONCAT(DISTINCT v.PrefLabel) AS AssociatedLabels
FROM Webpages w
JOIN Scores s ON w.Hash = s.Hash
JOIN Vocab v ON s.QID = v.QID
GROUP BY w.Domain
ORDER BY LabelFrequency DESC;




# Top labels by frequency

WITH QIDFrequency AS (
    SELECT S.QID, COUNT(*) AS Frequency
    FROM Scores S
    GROUP BY S.QID
)
SELECT DISTINCT
    V.PrefLabel,
	S.QID,
    WP.Domain,
    QF.Frequency
FROM
    Scores S
JOIN
    Webpages WP ON S.Hash = WP.Hash
JOIN
    Vocab V ON S.QID = V.QID
JOIN
    QIDFrequency QF ON S.QID = QF.QID
ORDER BY
    QF.Frequency DESC, -- Order by frequency of QID first
    S.Score DESC -- Then by score as a secondary order
LIMIT 50;


# OR group domains

SELECT 
    V.QID,
    V.PrefLabel,
    COUNT(S.QID) AS Frequency,
    GROUP_CONCAT(DISTINCT WP.Domain) AS AssociatedDomains
FROM 
    Scores S
JOIN 
    Vocab V ON S.QID = V.QID
JOIN 
    Webpages WP ON S.Hash = WP.Hash
GROUP BY 
    V.QID, V.PrefLabel
ORDER BY 
    Frequency DESC
LIMIT 20;



# Top labels by domain

SELECT
    V.PrefLabel,
	WP.Domain,
    COUNT(*) AS LabelFrequency
FROM
    Vocab V
JOIN
    Scores S ON V.QID = S.QID
JOIN
    Webpages WP ON S.Hash = WP.Hash
WHERE
    WP.Domain LIKE 'devdiscourse.com'
GROUP BY
    V.PrefLabel
ORDER BY
    LabelFrequency DESC
LIMIT 15;


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

SELECT WP.Domain, COUNT(*) AS DomainFrequency
FROM Webpages WP
JOIN Scores S ON WP.Hash = S.Hash
JOIN Vocab V ON S.QID = V.QID
WHERE V.PrefLabel LIKE 'Christ%'
GROUP BY WP.Domain
ORDER BY DomainFrequency DESC
LIMIT 10;




# Select similar domains for a given domain based on N labels

WITH TopLabels AS (
    SELECT V.PrefLabel
    FROM Vocab V
    JOIN Scores S ON V.QID = S.QID
    JOIN Webpages WP ON S.Hash = WP.Hash
    WHERE WP.Domain = 'printyourfood.com'
    GROUP BY V.PrefLabel
    ORDER BY COUNT(*) DESC
    LIMIT 5
),
DomainLabelFrequency AS (
    SELECT WP.Domain, V.PrefLabel, COUNT(*) AS Frequency
    FROM Webpages WP
    JOIN Scores S ON WP.Hash = S.Hash
    JOIN Vocab V ON S.QID = V.QID
    WHERE V.PrefLabel IN (SELECT PrefLabel FROM TopLabels)
    GROUP BY WP.Domain, V.PrefLabel
),
SimilarDomains AS (
    SELECT DLF.Domain, SUM(DLF.Frequency) AS TotalFrequency
    FROM DomainLabelFrequency DLF
    JOIN TopLabels TL ON DLF.PrefLabel = TL.PrefLabel
    GROUP BY DLF.Domain
    HAVING DLF.Domain <> 'printyourfood.com'
)
SELECT Domain, TotalFrequency
FROM SimilarDomains
ORDER BY TotalFrequency DESC
LIMIT 10;




















Below is a SQL schema.  Provide 5 SQL queries and how they should be graphed (eg. what X,Y values and what chart type) to provide interesting insight that is best expressed graphically; eg. manipulations (average, max/min, etc) and/or relationships in a scatter plot.  No time-historical queries.  Also include a query that selects on a given domain and one that selects on a given QID.










1. Query to find the average score per domain for a specific label (QID):

SELECT w.Domain, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
JOIN Vocab v ON s.QID = v.QID
WHERE v.QID = 'Q22686' -- Replace with actual label ID
GROUP BY w.Domain
ORDER BY AvgScore DESC;

Graph:
- Chart Type: Bar chart
- X-axis: Domain (Text)
- Y-axis: Average Score (Numeric)
- This bar chart would show the average score for each domain for a particular subject label, allowing the viewer to quickly see which domains are more closely associated with that subject based on the scores.

2. Query to find the most common labels (QIDs) for a specific domain:

SELECT v.PrefLabel, COUNT(s.QID) AS LabelFrequency
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
JOIN Vocab v ON s.QID = v.QID
WHERE w.Domain = 'espn.com' -- Replace with actual domain
GROUP BY v.PrefLabel
ORDER BY LabelFrequency DESC
LIMIT 10;

Graph:
- Chart Type: Horizontal bar chart
- X-axis: Label Frequency (Numeric)
- Y-axis: PrefLabel (Text)
- This horizontal bar chart would display the top 10 most common labels for a given domain, ranked by how often they appear in the scores.

3. Query to find the distribution of scores for a specific domain:

SELECT s.Score, COUNT(*) AS ScoreCount
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
WHERE w.Domain = 'espn.com' -- Replace with actual domain
GROUP BY s.Score
ORDER BY s.Score;

Graph:
- Chart Type: Histogram
- X-axis: Score (Numeric)
- Y-axis: Score Count (Numeric)
- This histogram would show the distribution of scores for the chosen domain, allowing the viewer to understand the range and frequency of scores that the domain receives.



4. Query to compare the total number of unique labels assigned to webpages within each domain:


SELECT w.Domain, COUNT(DISTINCT s.QID) AS UniqueLabelCount
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Domain
ORDER BY UniqueLabelCount DESC
LIMIT 10;


Graph:
- Chart Type: Bar chart
- X-axis: Domain (Text)
- Y-axis: Unique Label Count (Numeric)
- This bar chart would show the top 10 domains ranked by the number of unique labels they have, indicating the diversity of content or subjects associated with each domain.


6. Query to find the correlation between the number of webpages and average scores within each domain for a specific label:


SELECT w.Domain, COUNT(w.Hash) AS WebpageCount, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
JOIN Vocab v ON s.QID = v.QID
WHERE v.QID = 'Q22686' -- Replace with actual label ID
GROUP BY w.Domain
HAVING COUNT(w.Hash) > 50 -- Filter for domains with a significant number of webpages
ORDER BY WebpageCount;



7. Query to find the correlation between the number of distinct labels (QIDs) and the average score for each domain:

SELECT w.Domain, COUNT(DISTINCT s.QID) AS DistinctLabelCount, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Domain
HAVING COUNT(DISTINCT s.QID) > 10 -- Filter for domains with a significant number of distinct labels
ORDER BY DistinctLabelCount;


Graph:
- Chart Type: Scatter plot
- X-axis: Distinct Label Count (Numeric)
- Y-axis: Average Score (Numeric)
- Each point represents a domain, and the plot would show if there is a correlation between the diversity of subjects a domain covers and the average score it receives.

8. Query to find the correlation between the frequency of a label across domains and the average score for that label within each domain:


SELECT w.Domain, COUNT(s.QID) AS LabelFrequency, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
JOIN Vocab v ON s.QID = v.QID
GROUP BY w.Domain, s.QID
HAVING LabelFrequency > 100 AND LabelFrequency < 3000 -- Filter for labels with a significant frequency within domains
ORDER BY LabelFrequency;


Graph:
- Chart Type: Scatter plot
- X-axis: Label Frequency (Numeric)
- Y-axis: Average Score (Numeric)
- Each point represents a domain with a particular label, and the plot would show if there is a correlation between how often a label is assigned within a domain and the average score for that label.

9. Query to find the correlation between the maximum score and the minimum score for labels within each domain:


SELECT w.Domain, MAX(s.Score) AS MaxScore, MIN(s.Score) AS MinScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Domain
HAVING COUNT(s.QID) > 20 -- Filter for domains with a significant number of scores
ORDER BY MaxScore;


Graph:
- Chart Type: Scatter plot
- X-axis: Min Score (Numeric)
- Y-axis: Max Score (Numeric)
- Each point represents a domain, and the plot would illustrate the range of scores within each domain, potentially indicating domains with more polarized content or broader subject matter coverage.










Here are five SQL queries along with descriptions of how they should be graphed:

1. Query: Average Score per Domain

SELECT w.Domain, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Domain;

Graph: Bar chart
- X-axis: Domains (categorical)
- Y-axis: Average Score (numerical)
- Each bar represents the average score of vocabularies referenced in webpages from a specific domain.

2. Query: Top 10 Vocabularies by Average Score

SELECT v.PrefLabel, AVG(s.Score) AS AvgScore
FROM Vocab v
JOIN Scores s ON v.QID = s.QID
GROUP BY v.PrefLabel
ORDER BY AvgScore DESC
LIMIT 10;

Graph: Horizontal bar chart
- X-axis: Average Score (numerical)
- Y-axis: Vocabulary PrefLabels (categorical, sorted by score)
- Each bar represents the average score of a vocabulary, showing the top 10 vocabularies with the highest scores.

3. Query: Count of Webpages per Domain

SELECT Domain, COUNT(*) AS WebpageCount
FROM Webpages
GROUP BY Domain;

Graph: Pie chart
- Segments: Domains (categorical)
- Segment size: Count of webpages (numerical)
- Each segment of the pie chart represents the proportion of webpages for each domain.

4. Query: Distribution of Scores for a Given QID

SELECT Score, COUNT(*) AS ScoreCount
FROM Scores
WHERE QID = 'specific_QID'
GROUP BY Score;

Graph: Histogram
- X-axis: Score bins (numerical)
- Y-axis: Count of Scores (numerical)
- The histogram shows the distribution of scores for a particular vocabulary item.

5. Query: Number of Vocabularies Referenced by Domain

SELECT w.Domain, COUNT(DISTINCT s.QID) AS VocabCount
FROM Webpages w
JOIN Scores s ON w.Hash = s.Hash
GROUP BY w.Domain;

Graph: Bar chart
- X-axis: Domains (categorical)
- Y-axis: Count of Unique Vocabularies (numerical)
- Each bar represents the number of unique vocabularies referenced in webpages from each domain.

6. Query: Scores for a Given Domain
SELECT s.QID, s.Score
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
WHERE w.Domain = 'si.com';

Graph: Scatter plot
- X-axis: QID (categorical)
- Y-axis: Score (numerical)
- Each point represents the score of a vocabulary item on webpages from a specific domain.

Each of these queries provides insights into the data that are best expressed visually, revealing patterns and distributions that might not be immediately obvious from raw data alone.







Based on the schema you've provided, here are five additional queries that could provide useful insights in scatter plot form:

10. Query to analyze the correlation between the number of webpages and the average score per domain:

```sql
SELECT w.Domain, COUNT(w.Hash) AS WebpageCount, AVG(s.Score) AS AvgScore
FROM Webpages w
JOIN Scores s ON w.Hash = s.Hash
GROUP BY w.Domain
HAVING WebpageCount > 50 -- Filter for domains with a significant number of webpages
ORDER BY WebpageCount;
```

Graph:
- Chart Type: Scatter plot
- X-axis: Webpage Count (Numeric)
- Y-axis: Average Score (Numeric)
- Each point represents a domain, showing if domains with more webpages tend to have higher or lower average scores.

11. Query to investigate the relationship between the crawl date and the average score for webpages:

```sql
SELECT w.CrawlDate, AVG(s.Score) AS AvgScore
FROM Webpages w
JOIN Scores s ON w.Hash = s.Hash
GROUP BY w.CrawlDate
ORDER BY w.CrawlDate;
```

Graph:
- Chart Type: Scatter plot
- X-axis: Crawl Date (Numeric, Unix Timestamp)
- Y-axis: Average Score (Numeric)
- Each point represents a crawl date, indicating if there's a trend in scores over time.

12. Query to explore the correlation between the number of labels (QIDs) per webpage and the webpage's average score:

```sql
SELECT w.Hash, COUNT(s.QID) AS LabelCount, AVG(s.Score) AS AvgScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Hash
HAVING LabelCount > 5 -- Filter for webpages with a significant number of labels
ORDER BY LabelCount;
```

Graph:
- Chart Type: Scatter plot
- X-axis: Label Count (Numeric)
- Y-axis: Average Score (Numeric)
- Each point represents a webpage, showing whether webpages with more labels have different average scores.

13. Query to determine if there is a correlation between the diversity of labels and the maximum score across domains:

```sql
SELECT w.Domain, COUNT(DISTINCT s.QID) AS DistinctLabelCount, MAX(s.Score) AS MaxScore
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY w.Domain
HAVING DistinctLabelCount > 10 -- Filter for domains with diverse labels
ORDER BY DistinctLabelCount;
```

Graph:
- Chart Type: Scatter plot
- X-axis: Distinct Label Count (Numeric)
- Y-axis: Max Score (Numeric)
- Each point represents a domain, showing the relationship between the diversity of content and the highest score achieved.

14. Query to analyze the correlation between the average score of a label and the number of distinct domains that label appears in:

```sql
SELECT s.QID, AVG(s.Score) AS AvgScore, COUNT(DISTINCT w.Domain) AS DomainCount
FROM Scores s
JOIN Webpages w ON s.Hash = w.Hash
GROUP BY s.QID
HAVING DomainCount > 10 -- Filter for labels that appear in multiple domains
ORDER BY DomainCount;
```

Graph:
- Chart Type: Scatter plot
- X-axis: Domain Count (Numeric)
- Y-axis: Average Score (Numeric)
- Each point represents a label, indicating if labels that appear across many domains have different average scores compared to those in fewer domains.