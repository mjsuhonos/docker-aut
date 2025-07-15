CREATE TABLE "Vocab" (
    "QID" TEXT NOT NULL,
    "PrefLabel" TEXT  NOT NULL,
    CONSTRAINT "pk_Vocab" PRIMARY KEY (
        "QID"
     )
    FOREIGN KEY("QID") REFERENCES "Scores" ("QID")
);

CREATE TABLE "Scores" (
    "Hash" TEXT  NOT NULL,
    "QID" TEXT NOT NULL,
    "Score" REAL   NOT NULL,
    "SuggestDate" INTEGER NOT NULL,
    CONSTRAINT "pk_Scores" PRIMARY KEY (
        "Hash","QID"
     )
);

CREATE TABLE "Webpages" (
    "Hash" TEXT NOT NULL,
    "CrawlDate" INTEGER NOT NULL,
    "Domain" TEXT  NOT NULL,
    "URL" TEXT  NOT NULL,
    CONSTRAINT "pk_Webpages" PRIMARY KEY (
        "Hash"
     )
     FOREIGN KEY("Hash") REFERENCES "Scores" ("Hash")
);

CREATE TABLE "Content" (
    "Hash" TEXT NOT NULL,
    "Text" TEXT  NOT NULL,
    "ExtractDate" INTEGER NOT NULL,
    CONSTRAINT "pk_Content" PRIMARY KEY (
        "Hash"
     )
     FOREIGN KEY("Hash") REFERENCES "Webpages" ("Hash")
);


CREATE INDEX "idx_Vocab_PrefLabel"
ON "Vocab" ("PrefLabel");

CREATE INDEX "idx_Webpages_Domain"
ON "Webpages" ("Domain");

CREATE INDEX "idx_Scores_QID"
ON "Scores" ("QID");






CREATE TABLE "Domains" (
    "Domain" TEXT  NOT NULL,
    "Max" REAL   NOT NULL,
    "Avg" REAL   NOT NULL,
    "Min" REAL   NOT NULL,
	"LabelCount" INTEGER NOT NULL,
	"UniqueLabelCount" INTEGER NOT NULL,
    CONSTRAINT "pk_Domains" PRIMARY KEY (
        "Domain"
     )
     FOREIGN KEY("Domain") REFERENCES "Webpages" ("Domain")
);

INSERT INTO "Domains" ("Domain", "Max", "Avg", "Min", "LabelCount", "UniqueLabelCount")
SELECT
    w."Domain",
    MAX(s."Score") AS "Max",
    AVG(s."Score") AS "Avg",
    MIN(s."Score") AS "Min",
	COUNT(s.QID) AS "LabelCount",
	COUNT(DISTINCT s.QID) AS "UniqueLabelCount"
FROM "Scores" s
JOIN "Webpages" w ON s."Hash" = w."Hash"
GROUP BY w."Domain";





CREATE TABLE "Labels" (
    "QID" TEXT  NOT NULL,
    "Max" REAL   NOT NULL,
    "Avg" REAL   NOT NULL,
    "Min" REAL   NOT NULL,
	"ScoreCount" INTEGER NOT NULL,
	"UniqueDomainCount" INTEGER NOT NULL,
    CONSTRAINT "pk_Labels" PRIMARY KEY (
        "QID"
     )
     FOREIGN KEY("QID") REFERENCES "Scores" ("QID")
     FOREIGN KEY("QID") REFERENCES "Vocab" ("QID")
);

INSERT INTO "Labels" ("QID", "Label", "Max", "Avg", "Min", "ScoreCount", "UniqueDomainCount")
SELECT
    s."QID",
	v."PrefLabel" AS "Label",
    MAX(s."Score") AS "Max",
    AVG(s."Score") AS "Avg",
    MIN(s."Score") AS "Min",
	COUNT(s."QID") AS "ScoreCount",
	COUNT(DISTINCT w."Domain") AS "UniqueDomainCount"
FROM "Scores" s
JOIN "Webpages" w ON s."Hash" = w."Hash"
JOIN "Vocab" v ON s."QID" = v."QID"
GROUP BY s."QID";




