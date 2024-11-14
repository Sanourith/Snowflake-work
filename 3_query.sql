-- QUERY PART --

-- Create a stage to store my information in .txt format
CREATE OR REPLACE STAGE sanou_stage
  FILE_FORMAT = (TYPE = 'CSV' FIELD_OPTIONALLY_ENCLOSED_BY='"' FIELD_DELIMITER=',');

list@sanou_stage;

-- Create a temporary table to store query results in a 2-column format: Query / Result
DROP TABLE IF EXISTS STAR_SCHEMA.Temp_Results;
CREATE OR REPLACE TEMPORARY TABLE Temp_Results (
    "Query" VARCHAR,
    Result VARCHAR
);

-- List the album titles that have more than 1 CD.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the album titles that have more than 1 CD.', "AlbumTitle" FROM Star_Schema.New_tracks 
WHERE "CD_number" > 1
GROUP BY "AlbumTitle";

-- List the tracks produced in 2000 or 2002.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the tracks produced in 2000 or 2002.', "TrackName" || ' (' || "ProductionYear" || ')' FROM Star_Schema.New_tracks 
WHERE "ProductionYear" IN (2000, 2002)
ORDER BY "ProductionYear" ASC;

-- List the name and composer of Rock and Jazz tracks.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the name and composer of Rock and Jazz tracks.', "TrackName" || ' - ' || "Composer" || ' - ' || "GenreName" FROM Star_Schema.New_tracks 
WHERE "GenreName" IN ('Rock', 'Jazz');

-- List the top 10 longest albums.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the top 10 longest albums', "AlbumTitle" || ' - ' || sum("TrackTime") || ' ms' FROM Star_Schema.New_tracks 
GROUP BY "AlbumTitle"
ORDER BY sum("TrackTime") DESC
LIMIT 10;

-- List the number of albums produced by each artist.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the number of albums produced by each artist', "ArtistName" || ' - ' || count(distinct"AlbumId") FROM Star_Schema.New_tracks
GROUP BY "ArtistName"
ORDER BY "ArtistName" ASC;

-- List the number of tracks produced by each artist.
INSERT INTO STAR_SCHEMA.Temp_Results 
SELECT 'List the number of tracks produced by each artist', "ArtistName" || ' - ' || count("TrackId") FROM Star_Schema.New_tracks
GROUP BY "ArtistName";

-- List the most popular music genre in the 2000s.
INSERT INTO STAR_SCHEMA.Temp_Results 
SELECT 'List the most popular music genre in the 2000s', "GenreName" || ' - ' || count("TrackId") FROM Star_Schema.New_tracks
WHERE "ProductionYear" BETWEEN 2000 AND 2009
GROUP BY "GenreName"
ORDER BY count("TrackId") DESC
LIMIT 1;

-- List the names of all playlists that contain tracks longer than 4 minutes.
-- 4 minutes = 4 x 60 x 1000 milliseconds = 240000 ms
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the names of all playlists that contain tracks longer than 4 minutes.', "PlayListName" FROM Star_Schema.New_tracks
WHERE "TrackTime" > 240000
GROUP BY "PlayListName";

-- List the Rock tracks by artists from France.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the Rock tracks by artists from France.', "TrackName" FROM Star_Schema.New_tracks
WHERE "GenreName" = 'Rock' AND "Country" = 'France';

-- List the average track size by music genre.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the average track size by music genre.', "GenreName" || ' - ' || AVG("Memory (B)") || ' Bytes' FROM Star_Schema.New_tracks
GROUP BY "GenreName";

-- List the playlists that contain tracks by artists born before 1990.
INSERT INTO STAR_SCHEMA.Temp_Results
SELECT 'List the playlists that contain tracks by artists born before 1990.', "PlayListName" FROM Star_Schema.New_tracks
WHERE "Birthyear" < 1990
GROUP BY "PlayListName";

-- Copy the results to my answer.txt file:
CREATE OR REPLACE FILE FORMAT text_format
  TYPE = 'CSV'
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  FIELD_DELIMITER = '|'  -- Can also be ",", etc.
  NULL_IF = ('NULL', 'null', '')
  COMPRESSION = NONE;
  
COPY INTO @sanou_stage/answer.txt
FROM (SELECT "Query" || ': ' || Result AS Line FROM STAR_SCHEMA.Temp_Results)
FILE_FORMAT = (FORMAT_NAME = 'text_format')
SINGLE = TRUE;

list@sanou_stage;