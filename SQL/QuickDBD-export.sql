CREATE TABLE "Wikidata" (
    "QID" TEXT NOT NULL,
    "PrefLabel" TEXT  NOT NULL,
    CONSTRAINT "pk_Wikidata" PRIMARY KEY (
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


CREATE INDEX "idx_Wikidata_PrefLabel"
ON "Wikidata" ("PrefLabel");

CREATE INDEX "idx_Webpages_Domain"
ON "Webpages" ("Domain");